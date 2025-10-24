## 备份单个namespace下的ingress
#!/bin/bash
set -euo pipefail

NAMESPACE="${1}"
BACKUP_DIR="./ingress-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/ingress_${NAMESPACE}_${TIMESTAMP}.yaml"

log_info() {
    echo "[INFO] $1"
}
log_err() { echo "[ERROR] $1" }
mapfile -t INGRESS_ARRAY < <(kubectl get ingress -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

INGRESS_COUNT=${#INGRESS_ARRAY[@]}

if [ "$INGRESS_COUNT" -eq 0 ]; then
    echo "没有找到 Ingress 资源"
    exit 0
fi

#echo "找到 $INGRESS_COUNT 个 Ingress 资源:"
#printf "  - %s\n" "${INGRESS_ARRAY[@]}"

> "$BACKUP_FILE"

# 使用 for 循环避免管道问题,while有管道问题，会只备份第一个
for i in "${!INGRESS_ARRAY[@]}"; do
    INGRESS_NAME="${INGRESS_ARRAY[$i]}"
    echo "备份 ($((i+1))/$INGRESS_COUNT): $INGRESS_NAME"
    
    kubectl get ingress -n "$NAMESPACE" "$INGRESS_NAME" -o yaml >> "$BACKUP_FILE"
    
    # 在资源之间添加分隔符（除了最后一个）
    if [ $i -lt $((INGRESS_COUNT-1)) ]; then
        echo "---" >> "$BACKUP_FILE"
    fi
done
BACKUP_COUNT=$(grep -c "^apiVersion:" "$BACKUP_FILE" 2>/dev/null || echo 0)

echo "备份完成: $BACKUP_FILE"
echo "期望: $INGRESS_COUNT, 实际: $BACKUP_COUNT"
