## 用途: 替换ingress nginx
## 整体逻辑 gateway api 做网关管理，gateway class 对应 ingressclass,作为控制器绑定aws lb,映射去绑定gateway就行
1.安装扩展模式gateway api到k8s
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
2.安装envoy gateway
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.8.0 -n envoy-gateway-system --create-namespace
## example app 测试
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.8.0/quickstart.yaml -n default

3.测试
kubectl apply -f prometheus-test-httproute.yaml

4.访问页面验证


FAQ
1.Error: INSTALLATION FAILED: failed to perform "FetchReference" on source: GET "https://registry-1.docker.io/v2/envoyproxy/gateway-helm/manifests/v1.8.0": Cannot autolaunch D-Bus without X11 $DISPLAY
原因: docker 图形凭据助手导致
解决: sudo mv /usr/bin/docker-credential-secretservice /usr/bin/docker-credential-secretservice.bak

2.

3.

参考链接:
1.gateway-api: https://gateway-api.sigs.k8s.io/guides/getting-started/introduction/
2.envoy: https://gateway.envoyproxy.io/docs/tasks/quickstart/
