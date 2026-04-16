helm install grafana grafana/grafana \
  --namespace vm --create-namespace \
  --set persistence.enabled=true \
  --set persistence.storageClassName=efs \
  --set persistence.size=10Gi \
  --set adminUser=admin \
  --set adminPassword=VZrGk0neLd3gW3sfsuN9u6mf0vssvYktOsxZc9Ao \
  --set plugins=grafana-clock-panel,grafana-piechart-panel,victoriametrics-logs-datasource
