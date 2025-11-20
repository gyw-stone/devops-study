### 对于saas服务，只给域名反向代理配置；且saas那边域名不方便配置
## wp externalname
apiVersion: v1
kind: Service
metadata:
  name: external-wp-service-new
  namespace: cctip
spec:
  externalName: officialdffbe766b0-ehqpo.wpcomstaging.com # 外部dns
  ports:
    - port: 443
      protocol: TCP
      targetPort: 443
  sessionAffinity: None
  type: ExternalName



## ingress nginx配置
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/upstream-vhost: officialdffbe766b0-ehqpo.wpcomstaging.com
  name: wp-outside
  namespace: cctip
spec:
  ingressClassName: cctip-nginx
  rules:
    - host: cwallet.com
      http:
        paths:
          - backend:
              service:
                name: external-wp-service-new
                port:
                  number: 443
            path: /learn
            pathType: Prefix

## cloudfront 函数重定向
function handler(event) {
  var req = event.request;
  if (req.uri === "/learn") {
    return {
      statusCode: 302,
      statusDescription: "Moved Permanently",
      headers: { "location": { value: req.uri + "/" } }
    };
  }
  return req;
}

