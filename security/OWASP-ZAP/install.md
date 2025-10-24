# 下载安装包
wget https://github.com/zaproxy/zaproxy/releases/download/v2.16.1/ZAP_2_16_1_unix.sh
# 下载依赖jdk
apt update 
apt search openjdk-
sudo apt install openjdk-25-jdk
# 安装ZAP
sh ZAP_xxx
# 启动ZAP
zap.sh -daemon -port 8080 -config api.disablekey=true &
# 测试ZAP,200 为OK
curl -v http://localhost:8080/JSON/core/view/version/ 
# 使用流程,必须要能通到域名的网
1.添加URL到站点树,返回{"scan":"0"}类似
curl "http://localhost:8080/JSON/spider/action/scan/?url=https://test.com&recurse=true"
2.轮询spider状态直到完成，返回{"status":"100"}说明完成
curl "http://localhost:8080/JSON/spider/view/status/?scanId=0"
3.确认站点树有内容
curl "http://localhost:8080/JSON/core/view/sites/"
4.再跑主动扫描,攻击扫描
curl "http://localhost:8080/JSON/ascan/action/scan/?url=https://test.com&recurse=true"
curl "http://localhost:8080/JSON/ascan/view/status/?scanId=0" ## 查看扫描进度
5.导出为html
curl "http://localhost:8080/OTHER/core/other/htmlreport/" -o cwallet-report.html
6.systemd 管理
# 注释
api.addrs.addr.name=.* 允许所有 IP 访问
api.addrs.addr.regex=true 表示用正则匹配 IP
api.disablekey=true 关闭 API Key（在内网或安全网络下使用，公

# cat /etc/systemd/system/zap.service
[Unit]
Description=OWASP ZAP Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zap.sh -daemon -host 0.0.0.0 -port 8080 -config api.disablekey=true -config api.addrs.addr.name=.* -config api.addrs.addr.regex=true
WorkingDirectory=/root/.ZAP/
Restart=always
User=root 

[Install]
WantedBy=multi-user.target
7.任务管理
# 暂停指定任务
curl "http://localhost:8080/JSON/ascan/action/pause/?scanId=0"
# 恢复任务
curl "http://localhost:8080/JSON/ascan/action/resume/?scanId=0"
# 停止扫描
curl "http://localhost:8080/JSON/ascan/action/stop/?scanId=0"
# 查看扫描状态
curl "http://localhost:8080/JSON/ascan/view/status/?scanId=0"
# 查看详细扫描进度
curl "http://localhost:8080/JSON/ascan/view/scanProgress/?scanId=0"
# 暂停某个插件
curl "http://localhost:8080/JSON/ascan/action/disableScanners/?ids=10104&scanId=0"

## 使用流程shell
#!/bin/bash
set -o errexit
set -o pipefail
domain_name=$1
validate_domain() {
  if [[ ! "$domain_name" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]+$ ]]; then
    echo "❌ 域名格式错误: $domain_name"
    exit 1
  fi
}
# 检测zap服务
check_status(){
  curl -s -f -I "http://localhost:8080/JSON/core/view/version/" >/dev/null
}
add_domain(){
  curl -s "http://localhost:8080/JSON/spider/action/scan/?url=https://$domain_name&recurse=true" \
    | sed -n 's/.*"scan":"\([0-9]\+\)".*/\1/p'
}
spider(){
  local scan_id="$1"
  curl -s "http://localhost:8080/JSON/spider/view/status/?scanId=$scan_id" | sed -n 's/.*"status":"\([0-9]\+\)".*/\1/p'
}
check_url_tree(){
  curl -s "http://localhost:8080/JSON/core/view/sites/"
}
main() {
  validate_domain
  echo "✅ 域名格式正确: $domain_name"

  echo "🔍 检查ZAP服务状态..."
  check_status || { echo "❌ ZAP服务不可用"; exit 1; }

  echo "启动Spider扫描..."
  scan_id=$(add_domain)
  if [[ -z "$scan_id" || "$scan_id" == "null" ]]; then
    echo "❌ 获取scanId失败"
    exit 1
  fi
  echo "📌 扫描ID: $scan_id"

  echo "⏳ 等待Spider完成..."
  while true; do
    status=$(spider "$scan_id")
    [[ "$status" == "100" ]] && break
    echo "   Spider进度: $status%"
    sleep 5
  done
  echo "✅ Spider扫描完成"

  check_url_tree || { echo "❌ 无法获取站点树"; exit 1; }
}

main "$@"
