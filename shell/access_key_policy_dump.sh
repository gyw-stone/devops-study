#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: access_key_policy_dump.sh <access-key-id>

Flow:
1. aws iam get-access-key-last-used
2. aws iam list-user-policies
3. aws iam get-user-policy

All command outputs are written to /tmp/.
EOF
}

require_aws() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLI not found in PATH" >&2
    exit 1
  fi
}

get_access_key_last_used() {
  local access_key_id="$1"
  local output_file="/tmp/access-key-last-used-${access_key_id}.json"

  aws iam get-access-key-last-used \
    --access-key-id "$access_key_id" \
    --output json >"$output_file"

  aws iam get-access-key-last-used \
    --access-key-id "$access_key_id" \
    --query 'UserName' \
    --output text
}

list_user_policies() {
  local user_name="$1"
  local output_file="/tmp/list-user-policies-${user_name}.json"

  aws iam list-user-policies \
    --user-name "$user_name" \
    --output json >"$output_file"

  aws iam list-user-policies \
    --user-name "$user_name" \
    --query 'PolicyNames[]' \
    --output text
}

get_user_policy() {
  local user_name="$1"
  local policy_name="$2"
  local safe_policy_name
  safe_policy_name="$(printf '%s' "$policy_name" | tr '/ :' '___')"
  local output_file="/tmp/get-user-policy-${user_name}-${safe_policy_name}.json"

  aws iam get-user-policy \
    --user-name "$user_name" \
    --policy-name "$policy_name" \
    --output json >"$output_file"
}

main() {
  local access_key_id="${1:-}"
  local user_name
  local policy_names
  local policy_name

  if [ "$#" -ne 1 ] || [ -z "$access_key_id" ]; then
    usage
    exit 1
  fi

  require_aws

  user_name="$(get_access_key_last_used "$access_key_id")"
  echo "Resolved IAM user: $user_name" >&2
  if [ -z "$user_name" ] || [ "$user_name" = "None" ]; then
    echo "No IAM user found for access key: $access_key_id" >&2
    exit 1
  fi

  policy_names="$(list_user_policies "$user_name" | tr '\t' '\n')"
  if [ -z "$policy_names" ] || [ "$policy_names" = "None" ]; then
    echo "No inline user policies found for IAM user: $user_name" >&2
    exit 0
  fi

  while IFS= read -r policy_name; do
    [ -z "$policy_name" ] && continue
    echo "Fetching inline policy: $policy_name" >&2
    get_user_policy "$user_name" "$policy_name"
  done <<EOF
$policy_names
EOF

  echo "Finished. Files written under /tmp/ for user: $user_name"
}

main "$@"
