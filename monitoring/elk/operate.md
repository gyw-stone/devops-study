1.## es 相关接口
GET cctip2-log-2025.06.23-001779/_ilm/explain
GET _cluster/allocation/explain
# 集群设置
GET _cluster/settings
# 再次执行分配,报错分片未分配完执行
POST /_cluster/reroute?retry_failed=true
# 集群状态
GET _cluster/health
# 节点状态
GET _cat/nodes?v
GET _cat/health
# 分配详情
GET _cat/allocation?v
# 节点jvm 详情
GET /_nodes/stats/jvm?pretty


2.## es 查看唯一IP访问数
GET /cctip_nginx_record-2025.12.05/_search
{
  "track_total_hits": 100000, 
  "size": 0,
  "query": {
    "range": {
      "@timestamp": {
        "gte": "2025-12-05T07:30:00",
        "lt": "2025-12-05T07:40:00"
      }
    }
  },
  "aggs": {
    "unique_ips": {
      "cardinality": {
        "field": "client_ip.keyword"
      }
    },
    "top_30_ips": {
      "terms": {
        "field": "client_ip.keyword",
        "size": 10
      }
    }
  }
}

3.## 查看所有用户
curl -k -u user:pass -X GET "https://localhost:9200/_security/user?pretty"
## 删除kibana_k8s用户
curl -k -u user:pass -X DELETE "https://localhost:9200/_security/user/kibana_k8s"
## 删除role
curl -k -u user:pass -X DELETE "https://localhost:9200/_security/role/kibana_k8s_role"

4.## 查看状态
curl -k -u user:pass https://localhost:9200/_cluster/health
## 
5.## 优化集群并发和传输速率设置，以提高恢复性能和资源利用率：
PUT /_cluster/settings
{
  "transient": {
    "indices.recovery.max_bytes_per_sec": "150mb",
    "cluster.routing.allocation.node_concurrent_recoveries": 6,
    "cluster.routing.allocation.node_concurrent_incoming_recoveries": 6,
    "cluster.routing.allocation.node_concurrent_outgoing_recoveries": 8 
  }
}

6.##开启监控
# 开启监控功能
xpack.monitoring.collection.enabled: true

# dnf install metricbeat
metricbeat modules enable elasticsearch
# metricsbeat api key
POST /_security/api_key
{
  "name": "metricbeat_monitor_key",
  "role_descriptors": {
    "metricbeat_monitoring_role": {
      "cluster": [
        "monitor",
        "read_ilm",
        "manage_ilm",
        "manage_index_templates",
        "cluster:admin/xpack/monitoring/bulk"
      ],
      "indices": [
        {
          "names": [".monitoring-*", "metricbeat-*"],
          "privileges": ["all"]
        }
      ]
    }
  }
}
