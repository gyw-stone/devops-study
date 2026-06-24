## 
作用：收集日志
工具名字：victorialogs
日志收集工具: Promtail

## 1. 安装vlc single
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm repo update
helm show values vm/victoria-logs-cluster > values.yaml
helm install vlc vm/victoria-logs-cluster -f values.yaml -n NAMESPACE --debug

##  2. 安装promtail
kubectl apply -f promtail/all-deploy.yaml