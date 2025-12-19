#!/bin/bash
set -euo

## 查询mysql的private ip
rds_query() {
  local mysql_endpoint="xxx.ap-northeast-1.rds.amazonaws.com"
  if command -v dig >/dev/null 2>&1; then
     public_ip=$(dig +short "$mysql_endpoint" | grep '^[0-9].*')
     private_ip=$(/usr/local/sbin/aws ec2 describe-network-interfaces  --query "NetworkInterfaces[?Association.PublicIp=='$public_ip'].[PrivateIpAddress]" --output text)
     printf "%s" "$private_ip"
  fi
  
}
## 获取指定目标群组的注册目标IP
get_tg_ips() {
  local tg_arn="$1"
  tg_ip=$(/usr/local/sbin/aws elbv2 describe-target-health \
    --target-group-arn "arn:aws:elasticloadbalancing:ap-northeast-1:249539173837:targetgroup/NLb-ip-mysql/ceabc4c0a0fb12fd" \
    --query "TargetHealthDescriptions[].Target.Id" \
    --output text)
  printf "%s" "$tg_ip"
}
## 判断private ip是否已注册，未注册就注册
check_ip_in_tg() {
  local private_ip=$(rds_query)
  shift
  local tg_ips="$(get_tg_ips)"
  #echo "$tg_ips"

  if echo "$tg_ips" | grep -qw "$private_ip"; then
    echo "<U+2705> $private_ip is registered in Target Group"
  else
    /usr/local/sbin/aws elbv2 register-targets --target-group-arn "arn:aws:elasticloadbalancing:ap-northeast-1:249539173837:targetgroup/NLb-ip-mysql/ceabc4c0a0fb12fd" --targets Id="$private_ip",Port="3306" 
    echo "<U+274C> $private_ip is NOT registered in Target Group"
  fi
}

check_aws() {
  if command -v aws >/dev/null 2>&1; then
     check_ip_in_tg
  else
    echo "aws CLI not found, exiting."
    exit 1
  fi
}
# 执行
#check_aws
