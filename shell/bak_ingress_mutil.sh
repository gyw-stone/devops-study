#!/bin/bash

# 批量备份多个命名空间的 Ingress

set -e

BACKUP_DIR="/var/backups/k8s-ingress"
LOG_DIR="/var/log/k8s-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/ingress_backup_all_${TIMESTAMP}.log"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 要备份的命名空间列表
NAMESPACES=("default" "production" "staging" "monitoring")

log "开始批量备份 Ingress"

TOTAL_SUCCESS=0
TOTAL_FAILED=0

for NS in "${NAMESPACES[@]}"; do
    log "处理命名空间: $NS"
    
    # 调用单个备份脚本
    if "./bak_ingress.sh" "$NS" 2>/dev/null; then
        log "✅ $NS: 备份成功"
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
    else
        log "❌ $NS: 备份失败"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
done

log "批量备份完成: 成功 $TOTAL_SUCCESS, 失败 $TOTAL_FAILED"
