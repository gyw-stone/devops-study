
### 推送aws ec2 stopped 状态实例到fs群

#!/bin/bash
set -euo pipefail
# 区域
export AWS_REGION="ap-northeast-1"
# WEBHOOK_URL
WEBHOOK_URL="https://open.larksuite.com/open-apis/bot/v2/hook/060f94fa-48a9-4a12-8b2e-4c9d06807855"
notify() {
  local status; status="$1"
  local msg; msg="$2"
  if [[ -z "$WEBHOOK_URL" ]]; then
    echo "ERROR: WEBHOOK_URL is empty" >&2
    return 1
  fi
  local payload="{\"msg_type\":\"text\",\"content\":{\"text\":\"Status: ${status}\\nMessage: ${msg}\"}}"
  echo "通知发送内容: $payload" >&2
  curl -v -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" || {
    echo "ERROR: curl notify failed" >&2
    return 1
  }
}
check() {
  # 获取停止实例的私有IP列表
  stats=$(aws ec2 describe-instances \
    --filters Name=instance-state-name,Values=stopped \
    --query "Reservations[].Instances[].PrivateIpAddress" \
    --output text)

  # 检查是否有停止的实例
  if [ -n "$stats" ]; then
    echo "发现停止的EC2实例，私有IP列表："
    echo "$stats"
    notify "SUCCESS" "发现停止的EC2实例，私有IP列表：$stats"
    echo "告警已发送至飞书"
  else
    echo "没有检测到停止的EC2实例"
  fi
}
main(){
  check
}
main
