#!/bin/bash
LOG_FILE="./log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
SEPARATOR="##########"
echo "$SEPARATOR 任务启动 [$TIMESTAMP] $SEPARATOR" | tee -a "$LOG_FILE"
/bin/bash /root/global-accelerator/acc-create.sh wireguard-dev.yaml wireguard-ops.yaml  >> "$LOG_FILE" 2>&1
echo "$SEPARATOR 任务结束 [$(date '+%Y-%m-%d %H:%M:%S')] $SEPARATOR" | tee -a "$LOG_FILE"
echo -e "\n" >> "$LOG_FILE"  # 追加空行分隔
