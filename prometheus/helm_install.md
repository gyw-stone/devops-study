## add repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

## update local index 
helm repo update

## create namespace
kubectl create prometheus
