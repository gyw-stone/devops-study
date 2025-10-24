#!/bin/bash
set -eo pipefail

CONFIG_FILE="ecr_repos.config"
REPORT_FILE="ecr_scan_report_$(date +%Y%m%d).csv"
LARK_WEBHOOK="https://open.larksuite.com/open-apis/bot/v2/hook/060f94fa-48a9-4a12-8b2e-4c9d06807855"
MAX_PARALLEL=10  # 并发查询数

# 初始化CSV报告头
init_report() {
  echo "RepositoryName,CVE_ID,Source_URL,Severity,Package,Version,ScanTime" > "$REPORT_FILE"
}

check_aws_auth() {
  if ! /usr/local/sbin/aws sts get-caller-identity &> /dev/null; then
    echo "AWS认证失败！请检查凭证"
    exit 1
  fi
}

# 第一次初始化仓库列表配置文件
generate_repo_list() {
  if [ ! -f "$CONFIG_FILE" ] || [ "$(wc -l < "$CONFIG_FILE")" -eq 0 ]; then
    echo " 生成仓库列表..."
    aws ecr describe-repositories \
      --query 'repositories[].repositoryName' \
      --output text | tr '\t' '\n' > "$CONFIG_FILE"
  fi
}

# 获取仓库的扫描结果 (核心函数)
get_single_repo_result() {
  local repo="$1"

  # 查询扫描结果
  if ! /usr/local/sbin/aws ecr describe-image-scan-findings \
    --repository-name "$repo" \
    --image-id imageTag=latest \
    --query "imageScanFindings.enhancedFindings[?severity==\`HIGH\`].{
      Repo: '$repo',
      CVE: packageVulnerabilityDetails.vulnerabilityId,
      URL: packageVulnerabilityDetails.sourceUrl,
      Severity: severity,
      Package: packageVulnerabilityDetails.vulnerablePackages[0].name,
      Version: packageVulnerabilityDetails.vulnerablePackages[0].version,
      Time: to_string(imageScanFindings.imageScanCompletedAt)
    }" \
    --output text 2>/dev/null | \
    awk -v repo="$repo" 'BEGIN {FS="\t"; OFS=","} {
      if ($1 != "") print repo, $1, $2, $3, $4, $5, $6
    }' >> "$REPORT_FILE"
  then 
    echo "获取仓库 $repo 结果失败" >&2
  fi
}

# 并发获取所有仓库结果
parallel_fetch() {
  while IFS= read -r repo; do
    {
      get_single_repo_result "$repo"
    } >> "log_$(date +%Y%m%d).log" 2>&1 &
  done < "$CONFIG_FILE"

  wait  # 等待剩余任务
}
# 发送飞书通知
send_lark_alert() {
  local high_vulns
  local repo_count
  high_vulns=$(grep -c "HIGH" "$REPORT_FILE" || true)
  repo_count=$(wc -l < "$CONFIG_FILE")

  curl -X POST -H "Content-Type: application/json" -d \
  '{
    "msg_type": "interactive",
    "card": {
      "header": {
        "title": "ECR安全报告",
        "template": "'"$( [ "$high_vulns" -gt 0 ] && echo "red" || echo "green" )"'"
      },
      "elements": [
        {
          "tag": "div",
          "text": "**生成时间**: '"$(date)"'\n**仓库总数**: '"$repo_count"'\n**高危漏洞数**: '"$high_vulns"'"
        },
        {
          "tag": "note",
          "elements": [
            {
              "tag": "plain_text",
              "content": "详细报告: '"$(realpath "$REPORT_FILE")"'"
            }
          ]
        }
      ]
    }
  }' "$LARK_WEBHOOK"
}

# 主流程
main() {
  check_aws_auth
  init_report
  generate_repo_list
  parallel_fetch
  send_lark_alert
  echo "报告生成完成: $REPORT_FILE"
}

#trap 'echo "脚本被中断！"; exit 130' INT TERM
main
