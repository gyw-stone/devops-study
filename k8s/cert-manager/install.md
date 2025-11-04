## 采用helm方式安装
1.安装
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.1 \
  --set crds.enabled=true
2.配置 Issuers 
2.1 使用http01 为 solvers,kubectl apply -f 映射下面yaml
# letsencrypt-prod-issuers.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: stone0242@ccteam.net # 必须替换
    profile: tlsserver
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx
2.2 使用dns01方案，直接读取dns 记录信息
cat >certmanager-route53.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:GetChange"
            ],
            "Resource": "arn:aws:route53:::change/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "arn:aws:route53:::hostedzone/Z05196301TMZB2UTIIB6H" # dns 域名托管区域ID
        },
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones"
            ],
            "Resource": "*"
        }
    ]
}
EOF


-----------

aws iam create-policy --policy-name certmanager-route53-cctip-group --policy-document file://certmanager-route53.json

--------输出-------
{
    "Policy": {
        "PolicyName": "certmanager-route53",
        "PolicyId": "ANPATUGNRTXGRJZ2IH2Q7",
        "Arn": "arn:aws:iam::249539173837:policy/certmanager-route53",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2025-06-24T06:18:31+00:00",
        "UpdateDate": "2025-06-24T06:18:31+00:00"
    }
}

------


 eksctl create iamserviceaccount \
  --name cert-manager \
  --namespace cert-manager \
  --cluster eks-test \
  --role-name eks-test-certmanager-route53 \
  --attach-policy-arn arn:aws:iam::249539173837:policy/certmanager-route53-cctip-group \
  --approve --override-existing-serviceaccounts
  
  
-------
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-route53
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: you@example.com
    privateKeySecretRef:
      name: letsencrypt-route53
    solvers:
    - dns01:
        route53:
          hostedZoneID: Z05196301TMZB2UTIIB6H
          region: ap-northeast-1
          
------重启服务-----
kubectl rollout restart deployment cert-manager -n cert-manager
kubectl rollout restart deployment cert-manager-webhook -n cert-manager
kubectl rollout restart deployment cert-manager-cainjector -n cert-manage

3.Ingress 请求认证
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    # add an annotation indicating the issuer to use.
    cert-manager.io/cluster-issuer: letsemcrypt-prod # 对应上面的Issuers
  name: myIngress
  namespace: myIngress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: myservice
            port:
              number: 80
  tls: # < placing a host in the TLS config will determine what ends up in the cert's subjectAltNames
  - hosts:
    - example.com
    secretName: myingress-cert # < cert-manager will store the created certificate in this secret.

