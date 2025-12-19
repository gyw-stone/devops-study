#!/bin/bash
set -eo
NAMESPACES=("cctip" "merchant" "giveaway" "clickhouse" "middleware")
OUTPUT_CSV="zookeeper_configmap_scan.csv"

# 如果 namespace 数组为空则自动读取所有 ns
if [ ${#NAMESPACES[@]} -eq 0 ]; then
    mapfile -t NAMESPACES < <(kubectl get ns --no-headers -o custom-columns=":metadata.name")
fi

echo "Namespace,ConfigMap,ContainsZookeeper" > "$OUTPUT_CSV"

echo ""
echo "-----------------------------------------------"
echo "Scanning multiple namespaces for Zookeeper usage"
echo "-----------------------------------------------"

for ns in "${NAMESPACES[@]}"; do
    echo ">>> Namespace: $ns"

    mapfile -t CMS < <(kubectl get configmaps -n "$ns" --no-headers -o custom-columns=":metadata.name")

    for cm in "${CMS[@]}"; do
        yaml=$(kubectl get cm "$cm" -n "$ns" -o yaml)

        if echo "$yaml" | grep -qi "zookeeper"; then
            echo "$ns,$cm,YES" | tee -a "$OUTPUT_CSV"
        else
            echo "$ns,$cm,NO" | tee -a "$OUTPUT_CSV"
        fi
    done
    echo ""
done

echo ""
echo "✔ Scan completed. Results saved to: $OUTPUT_CSV"

