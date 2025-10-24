### 轻量化日志
1.vmlogs+promtail+grafana or vmlogs+promtail
2.grafana+loki+minio+promtail
### 这里用的2
## 操作
执行sh deploy.sh 或者 helm install grafana grafana/granafa -f values.yaml -n monitoring
helm install loki grafana/loki -f ./loki/values.yaml -n monitoring
然后promtail clents 绑定推送到loki
loki绑定数据源到grafana上
