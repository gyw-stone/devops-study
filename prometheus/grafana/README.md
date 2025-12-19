### 轻量化日志
1.vmlogs+promtail+grafana or vmlogs+promtail
2.grafana+loki+minio+promtail
### 这里用的2
## 操作
执行sh deploy.sh 或者 helm install grafana grafana/granafa -f values.yaml -n monitoring
helm install loki grafana/loki -f ./loki/values.yaml -n monitoring
然后promtail clents 绑定推送到loki
loki绑定数据源到grafana上

## 监控
1.grafana 模版
• 集群资源监控：3119
• 资源状态监控 ：6417
• Node监控 ：9276
2.grafana查询优化思路
highmax 函数 or alias别名 reduce the size of the returned series name
# 使用public dashboards，read-only，多次访问建议使用
# https://grafana.com/docs/grafana/latest/dashboards/dashboard-public/


## FQA
grafana 告警alertmanager 选择grafana 容易出现识别状态问题，特别是8.5.x版本，直接选择alertmanager更好
