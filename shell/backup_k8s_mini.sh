#!/bin/bash

set -eou pipeline
if ! command -v yq &> /dev/null; then
    sudo dnf install yq
fi

BACKUP_DIR="k8s-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR" && cd "$BACKUP_DIR"

# 需要清理的字段
CLEAN_FIELDS='del(
    .status,
    .metadata.managedFields,
    .metadata.resourceVersion,
    .metadata.uid,
    .metadata.creationTimestamp,
    .metadata.generation,
    .metadata.annotations,
    .spec.template.metadata.creationTimestamp,
    .spec.template.metadata.annotations
)'

# 命名空间级资源
NS_RESOURCES=("deployment" "statefulset" "daemonset" "service" "pvc" "configmap" "secret" "ingress" "cronjob")

# 集群级资源
CLUSTER_RESOURCES=("pv" "storageclass")

backup_resources() {
    local kind=$1
    local ns=$2
    local output_file=$3
    
    if [ -n "$ns" ]; then
        kubectl get "$kind" -n "$ns" -o yaml 2>/dev/null | yq eval "$CLEAN_CMD" - > "$output_file"
    else
        kubectl get "$kind" -o yaml 2>/dev/null | yq eval "$CLEAN_CMD" - > "$output_file"
    fi
    
    if [ -s "$output_file" ]; then
        local count=$(yq eval '.items | length' "$output_file" 2>/dev/null || echo 1)
        echo "  ✓ $kind ($count)"
    else
        rm -f "$output_file"
    fi
}

# 备份命名空间资源
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
    (
        mkdir -p "$ns"
        echo "*** 备份命名空间: $ns"
        for kind in "${NS_RESOURCES[@]}"; do
            backup_resources "$kind" "$ns" "$ns/${kind}.yaml"
        done
    ) &
    sleep 0.1
done

# 备份集群资源
(
    mkdir -p _cluster
    echo "*** 备份集群资源"
    for kind in "${CLUSTER_RESOURCES[@]}"; do
        backup_resources "$kind" "" "_cluster/${kind}.yaml"
    done
) &

wait

echo "==================================="
echo "✅ 备份完成！目录: $BACKUP_DIR"
echo "==================================="

# 显示统计
echo "备份统计:"
find . -name "*.yaml" -type f | wc -l | xargs echo "  - 总文件数:"
find . -type f -name "*.yaml" -exec du -h {} \; | awk '{total += $1} END {print "  - 总大小: " total "K"}'
