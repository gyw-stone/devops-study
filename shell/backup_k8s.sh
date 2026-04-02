#!/bin/bash

# 检查是否安装了 yq
if ! command -v yq &> /dev/null; then
    echo "❌ 请先安装 yq: https://github.com/mikefarah/yq#install"
    exit 1
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

# 并发备份命名空间资源
for ns in $(kubectl get ns --no-headers -o custom-columns=":metadata.name"); do
    (
        mkdir -p "$ns"
        echo "*** 备份命名空间: $ns"

        for kind in "${NS_RESOURCES[@]}"; do
            # check is exist
            if kubectl get "$kind" -n "$ns" &>/dev/null; then
                # 获取原始文件
                kubectl get "$kind" -n "$ns" -o yaml > "$ns/${kind}-raw.yaml" 2>/dev/null
                
                # clean and save
                if [ -s "$ns/${kind}-raw.yaml" ]; then
                    # 判断是列表还是单个资源
                    if grep -q "^items:" "$ns/${kind}-raw.yaml"; then
                        # 列表格式（多个资源）
                        yq eval "del(.items[].status, .items[].metadata.managedFields, .items[].metadata.resourceVersion, .items[].metadata.uid, .items[].metadata.creationTimestamp, .items[].metadata.generation) | del(.items[].metadata.annotations) | del(.items[].spec.template.metadata.creationTimestamp) | del(.items[].spec.template.metadata.annotations)" "$ns/${kind}-raw.yaml" > "$ns/${kind}.yaml"
                    else
                        # 单个资源
                        yq eval "$CLEAN_FIELDS" "$ns/${kind}-raw.yaml" > "$ns/${kind}.yaml"
                    fi
                    
                    # 删除原始文件
                    rm "$ns/${kind}-raw.yaml"
                    
                    # 统计数量
                    count=$(yq eval '.items | length' "$ns/${kind}.yaml" 2>/dev/null || echo 1)
                    echo "  ✓ $kind ($count)"
                fi
            fi
        done
    ) &
    
    # 控制并发数
    sleep 0.1
done

# 并发备份集群级资源
(
    mkdir -p _cluster
    echo "*** 备份集群资源"

    for kind in "${CLUSTER_RESOURCES[@]}"; do
        if kubectl get "$kind" &>/dev/null; then
            kubectl get "$kind" -o yaml > "_cluster/${kind}-raw.yaml" 2>/dev/null
            
            if [ -s "_cluster/${kind}-raw.yaml" ]; then
                if grep -q "^items:" "_cluster/${kind}-raw.yaml"; then
                    yq eval "del(.items[].status, .items[].metadata.managedFields, .items[].metadata.resourceVersion, .items[].metadata.uid, .items[].metadata.creationTimestamp, .items[].metadata.generation) | del(.items[].metadata.annotations) | del(.items[].spec.template.metadata.creationTimestamp) | del(.items[].spec.template.metadata.annotations)" "_cluster/${kind}-raw.yaml" > "_cluster/${kind}.yaml"
                else
                    yq eval "$CLEAN_FIELDS" "_cluster/${kind}-raw.yaml" > "_cluster/${kind}.yaml"
                fi
                
                rm "_cluster/${kind}-raw.yaml"
                count=$(yq eval '.items | length' "_cluster/${kind}.yaml" 2>/dev/null || echo 1)
                echo "  ✓ $kind ($count)"
            fi
        fi
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
