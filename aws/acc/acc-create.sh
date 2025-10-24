#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

COUNTER_DIR=".deploy_counters"
WEBHOOK_URL="https://open.larksuite.com/open-apis/bot/v2/hook/060f94fa-48a9-4a12-8b2e-4c9d06807855"
TEMPLATE_EXT=".yaml"

sanitize_var() {
  local var; var="$1"
  printf "%s" "$var" | sed -E 's/[^a-zA-Z0-9._-]+/_/g'
}

init_counter_file() {
  local base; base="$1"
  mkdir -p "$COUNTER_DIR"
  local file; file="${COUNTER_DIR}/$(sanitize_var "$base").count"
  if [[ ! -f "$file" ]]; then
    printf "1\n" > "$file"
  fi
  printf "%s" "$file"
}

read_and_increment_counter() {
  local file; file="$1"
  local count; count=$(<"$file")
  if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    printf "Invalid counter in %s\n" "$file" >&2
    return 1
  fi
  printf "%s" $((count + 1)) > "$file"
  printf "%s" "$count"
}

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

deploy_stack() {
  local template; template="$1"

  if [[ ! -f "$template" ]]; then
    printf "Template file not found: %s\n" "$template" >&2
    notify "FAIL" "创建 Global Accelerator: Template file not found: $template"
    return 1
  fi

  local base; base="${template%$TEMPLATE_EXT}"
  local counter_file; counter_file=$(init_counter_file "$base") || return 1
  local count; count=$(read_and_increment_counter "$counter_file") || return 1

  local stack_name="${base}-${count}"
  local acc_name="${base}-${count}"
  echo "### 调试查看acc_name ###"
  echo "acc_name: $acc_name"
  echo "### 调试结束 ###"
if ! /usr/local/sbin/aws cloudformation deploy \
    --template-file "$template" \
    --stack-name "$stack_name" \
    --parameter-overrides AcceleratorName="$acc_name"; then
      notify "FAIL" "创建 Global Accelerator (${acc_name}) 失败,请查看日志/root/global-accelerator/log"
      return 1
  fi

  local dns;
  if ! dns=$(/usr/local/sbin/aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --query "Stacks[0].Outputs[?OutputKey=='AcceleratorDNS'].OutputValue" \
    --output text); then
      notify "SUCCESS" "创建 Global Accelerator: ${acc_name}\n但无法获取 AcceleratorDNS"
      return 0
  fi

  if [[ -n "$dns" && "$dns" != "None" ]]; then
    notify "SUCCESS" "创建 Global Accelerator: ${acc_name}\nDNS: ${dns}"
  else
    notify "SUCCESS" "创建 Global Accelerator: ${acc_name}\n但无法获取 AcceleratorDNS"
  fi
}

main() {
  if [[ "$#" -eq 0 ]]; then
    printf "Usage: %s <template1.yaml> [template2.yaml ...]\n" "$0" >&2
    return 1
  fi

  local template;
  for template in "$@"; do
    deploy_stack "$template"
  done
}

main "$@"
