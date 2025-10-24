# 生成随机密码
LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+{}[]:;<>,.?/~' < /dev/urandom | head -c 64
# nginx basic auth
openssl passwd -apr1 'your-password'
echo -n 'username:$apr1$xxxxxx$yyyyyy' | base64
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: vmlogs-auth
  namespace: vm
type: Opaque
data:
  auth: aGFzaF9sb2dzOiRhcHIxJGhlVzlQVEMzJHQ1VjUxM01ydU5nQVVCb3ZsQTg1MzEK
# nginx ingress
annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: vmlogs-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
