########################################################################
##  现有LBC 添加 gatewayclass,LBC版本大于2.13                         ##
##  当前架构: service --> gateway api --> alb --> cloudfront --> R53  ##
##  测试工作跳过cloudfront                                            ##
########################################################################
1.准备工作：
# 安装gateway-api crds文件 v1正式版本目前不支持nlb ,使用nlb需要实验版本
kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
# 安装LBC crds文件
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/refs/heads/main/config/crd/gateway/gateway-crds.yaml
参考文档：[LBC](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/gateway/gateway/)

2.LBC 检测是否开启GatewayApi功能
kubectl get deploy -n kube-system aws-load-balancer-controller -o jsonpath='{.spec.template.spec.containers[0].args}'
如果没有开启,deployment args 添加 "--feature-gates=ALBGatewayAPI=true,NLBGatewayAPI=true" or 
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
   -n kube-system \
   --reuse-values \
   --set "controllerConfig.featureGates.NLBGatewayAPI=false" \
   --set "controllerConfig.featureGates.ALBGatewayAPI=true"

3.创建gatewayclass
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: aws-nlb
spec:
  controllerName: gateway.k8s.aws/nlb

4.检测gatewayclass 状态是否被accepted
kubectl get gatewayclass

5.创建gateway
---
# my-alb-gateway.yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: my-alb-gateway
  namespace: example-ns
spec:
  gatewayClassName: aws-alb-gateway-class
  infrastructure:
    parametersRef:
      kind: LoadBalancerConfiguration
      name: test-gw-lbconfig-1
      group: gateway.k8s.aws
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
    - name: https
      protocol: HTTPS
      port: 443
      allowedRoutes:
        namespaces:
          from: Same
---
# lbconfig.yaml
apiVersion: gateway.k8s.aws/v1beta1
kind: LoadBalancerConfiguration
metadata:
  name: test-gw-lbconfig-1
  namespace: example-ns
spec:
  scheme: internet-facing # 不带这个默认是internal
  listenerConfigurations:
    - protocolPort: HTTP:80

6.映射服务
---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-test-svc
  namespace: monitoring
spec:
  # 使用 NodePort 以满足 AWS LBC 的 Gateway API 校验要求
  type: NodePort 
  selector:
    app: nginx-test
  ports:
    - port: 80
      targetPort: 80
---
# httproute.yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: test-httproute
  namespace: monitoring
spec:
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: alb-gateway
      namespace: kube-system
      sectionName: http
  hostnames:
    - "nginxtest.io"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
    - backendRefs:
        - name: nginx-test-svc
          port: 80

7.验证
## 测试到alb是否OK，返回200是正常的
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: nginxtest.io" http://<ALB-DNS地址>/
## 直接测试域名是否OK
然后再直接curl -s -o /dev/null -w "%{http_code}\n" http://nginxtest.io

8.相关删除命令
kubectl patch gateway alb-gateway -n kube-system -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl delete -f xxx.yaml
