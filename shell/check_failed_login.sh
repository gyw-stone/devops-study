#!/bin/bash
WEBHOOK_URL="https://open.larksuite.com/open-apis/bot/v2/hook/01e1faec-8ec5-4925-9241-b7e2bcdb4c0f"
notify() {
  local status; status="$1"
  local msg; msg="$2"
  if [[ -z "$WEBHOOK_URL" ]]; then
    echo "ERROR: WEBHOOK_URL is empty" >&2
    return 1
  fi
  local payload="{\"msg_type\":\"text\",\"content\":{\"text\":\"Status: ${status}\\nMessage: ${msg}\"}}"
  echo "通知发送内容: $payload" >&2
  curl -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" || {
    echo "ERROR: curl notify failed" >&2
    return 1
  }
}
threshold_epoch=$(date -d '1 min ago' +%s)
IP=$(hostname -I | awk '{print $1}')
count=$(sudo lastb -n 50 -F | awk -v threshold_epoch="$threshold_epoch" '
{
  match($0, /[A-Z][a-z]{2} [A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}/, arr);
  if (arr[0] != "") {
    cmd = "date -d \"" arr[0] "\" +%s";
    cmd | getline log_epoch;
    close(cmd);
    if (log_epoch >= threshold_epoch) count++;
  }
}
END { print count+0 }')
if ! [[ $count =~ ^[0-9]+$ ]]; then
  count=0
else [[ $count -gt 5 ]]
 notify "登录失败次数告警" "当前主机: $IP 登录失败次数过多，失败次数为: $count"
fi
