## 开启spm jaeger配置env (k8s方式)
- name: COLLECTOR_OTLP_ENABLED
  value: 'true'
- name: METRICS_STORAGE_TYPE
  value: prometheus
- name: METRICS_STORAGE_PROMETHEUS_URL
  value: http://prometheus-server.prometheus.svc.cluster.local:80
- name: METRICS_BACKEND
  value: prometheus
- name: JAEGER_QUERY__MONITOR_MENU_ENABLED
  value: 'true'
