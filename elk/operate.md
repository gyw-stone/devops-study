## es 相关接口
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
