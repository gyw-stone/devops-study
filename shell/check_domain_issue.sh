#!/usr/bin/env bash

# ==============================================================================
# 作用: 快速定位域名映射问题
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_step() { echo -e "\n${BLUE}[STEP]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

prepare_env() {
    log_step "准备运行环境..."
    
    # 定义包管理器
    local pkg_manager=""
    if command -v dnf &> /dev/null; then pkg_manager="dnf";
    elif command -v apt-get &> /dev/null; then pkg_manager="apt-get";
    fi

    if ! command -v curl &> /dev/null; then
        log_warn "未检测到 curl，尝试安装..."
        sudo $pkg_manager install -y curl || log_err "安装 curl 失败，请手动处理。"
    fi

    if ! command -v dig &> /dev/null && ! command -v nslookup &> /dev/null; then
        log_warn "未检测到 dig/nslookup，尝试安装 dnsutils/bind-utils..."
        if [[ "$pkg_manager" == "dnf" ]]; then
            sudo dnf install -y bind-utils || log_err "安装失败。"
        else
            sudo apt-get update && sudo apt-get install -y dnsutils || log_err "安装失败。"
        fi
    fi
    log_success "环境检查通过。"
}

collect_inputs() {
    echo -e "${YELLOW}=== 请输入测试参数 ===${NC}"
    read -rp "1. 目标域名 (test.com): " DOMAIN
    read -rp "2. LB 地址 (xxx.elb...): " LB_DNS
    [[ -z "$DOMAIN" || -z "$LB_DNS" ]] && log_err "输入不能为空！"
}

get_ip() {
    local target=$1
    if command -v dig &> /dev/null; then
        dig +short "$target" | tail -n1
    else
        nslookup "$target" | grep "Address" | tail -n1 | awk '{print $2}'
    fi
}

# --- 4. 执行探测逻辑 ---
run_trace() {
    log_step "探测 A: DNS 解析状况"
    local domain_ip
    domain_ip=$(get_ip "$DOMAIN")
    if [[ -z "$domain_ip" ]]; then
        log_warn "域名 $DOMAIN 暂无解析。"
    else
        log_success "解析正常，当前指向 IP: $domain_ip"
    fi

    log_step "探测 B: 负载均衡层 (CloudFront/LB 入口)"
    local lb_ip
    lb_ip=$(get_ip "$LB_DNS")
    [[ -z "$lb_ip" ]] && log_err "无法解析 LB 地址: $LB_DNS"

    local code
    code=$(curl -k -s -o /dev/null -m 10 \
        --resolve "${DOMAIN}:443:${lb_ip}" \
        "https://${DOMAIN}" -w "%{http_code}")

    if [[ "$code" -eq "000" ]]; then
        log_err "无法连接 LB。请检查：1. 实例是否在线；2. 安全组是否放行 443 端口。"
    else
        log_success "LB 响应正常，状态码: $code"
    fi

    log_step "探测 C: Ingress/后端逻辑检查"
    local http_info
    # 强制 Host 头探测，分析 5xx 或 4xx 错误
    http_info=$(curl -I -s -H "Host: $DOMAIN" "http://$LB_DNS" | grep -E "HTTP/|Server:|x-cache:" || true)
    
    echo -e "${GREEN}[Header 信息]:${NC}\n$http_info"
    
    if [[ "$http_info" == *"504"* ]]; then
        log_warn "分析：检测到 504 Gateway Timeout。说明 LB 通了，但 Ingress 等待后端 Pod 响应超时。"
    elif [[ "$http_info" == *"404"* ]]; then
        log_warn "分析：检测到 404 Not Found。说明请求到了 Ingress，但没匹配到对应的 Ingress Rule。"
    elif [[ "$http_info" == *"502"* ]]; then
        log_warn "分析：检测到 502 Bad Gateway。通常是 Ingress 无法连接到后端的 Service 端口。"
    fi
}

main() {
    prepare_env
    collect_inputs
    run_trace
    log_step "探测任务结束。"
}

main


