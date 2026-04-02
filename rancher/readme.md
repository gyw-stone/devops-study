## eks 安装rancher,alb映射出去
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

kubectl create namespace cattle-system

kubectl -n cattle-system get deploy rancher

kubectl get setting server-url

 helm upgrade --install rancher ./rancher \
  --namespace cattle-system \
  --set hostname=rancher.xwally.com \
  --set bootstrapPassword=admin \
  --set tls=external \
  --set extraEnv[0].name=CATTLE_SERVER_URL \
  --set extraEnv[0].value=https://rancher.xwally.com \
  --set extraEnv[1].name=CATTLE_NAMESPACE \
  --set extraEnv[1].value=cattle-system


 alb.ingress.kubernetes.io/group.name: alb-group
    alb.ingress.kubernetes.io/group.order: '2'
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/load-balancer-name: eks-prod-alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/tags: Type=fixed,Purpose=placeholder
    alb.ingress.kubernetes.io/target-type: ip
