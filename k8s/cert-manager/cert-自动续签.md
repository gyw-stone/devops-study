cert-manager 配置IRSA(EKS)环境来授予IAM权限(支持route53）
## 创建权限策略文件
cat >certmanager-route53.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetChange",
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/Z043481422SSUXRDQ7DRI"
    },
    {
      "Effect": "Allow",
      "Action": ["route53:ListHostedZones"],
      "Resource": "*"
    }
  ]
}
EOF
## 创建策略
aws iam create-policy --policy-name certmanager-route53 --policy-document file://certmanager-route53.json

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
## eksctl 工具创建 IAM Role 并绑定到现有的 cert-manager service account
 eksctl create iamserviceaccount --name cert-manager --namespace cert-manager --cluster cluster-in-northeast-vpc --role-name <ROLE_NAME> \
    --attach-policy-arn arn:aws:iam::249539173837:policy/certmanager-route53 --approve --override-existing-serviceaccounts 
## 创建IRSA Role + 绑定 ServerAccount
eksctl create iamserviceaccount \
  --name cert-manager \
  --namespace cert-manager \
  --cluster cluster-in-northeast-vpc \
  --role-name eks-certmanager-route53 \
  --attach-policy-arn arn:aws:iam::249539173837:policy/certmanager-route53 \
  --approve --override-existing-serviceaccounts
  
  ------------输出----------------
  2025-06-24 06:49:31 [ℹ]  3 existing iamserviceaccount(s) (cctip/ecr-login-refresh,kube-system/aws-load-balancer-controller,prometheus/ec2-discovery-sa) will be excluded
2025-06-24 06:49:31 [ℹ]  1 iamserviceaccount (cert-manager/cert-manager) was included (based on the include/exclude rules)
2025-06-24 06:49:31 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2025-06-24 06:49:31 [ℹ]  1 task: { 
    2 sequential sub-tasks: { 
        create IAM role for serviceaccount "cert-manager/cert-manager",
        create serviceaccount "cert-manager/cert-manager",
    } }2025-06-24 06:49:31 [ℹ]  building iamserviceaccount stack "eksctl-cluster-in-northeast-vpc-addon-iamserviceaccount-cert-manager-cert-manager"
2025-06-24 06:49:31 [ℹ]  deploying stack "eksctl-cluster-in-northeast-vpc-addon-iamserviceaccount-cert-manager-cert-manager"
2025-06-24 06:49:31 [ℹ]  waiting for CloudFormation stack "eksctl-cluster-in-northeast-vpc-addon-iamserviceaccount-cert-manager-cert-manager"
2025-06-24 06:50:01 [ℹ]  waiting for CloudFormation stack "eksctl-cluster-in-northeast-vpc-addon-iamserviceaccount-cert-manager-cert-manager"
2025-06-24 06:50:01 [ℹ]  serviceaccount "cert-manager/cert-manager" already exists
2025-06-24 06:50:01 [ℹ]  updated serviceaccount "cert-manager/cert-manager"
## 配置 ClusterIssuer（使用 DNS-01 验证 + Route53）
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
          hostedZoneID: Z043481422SSUXRDQ7DRI
          region: ap-northeast-1
## Ingress 中绑定示例： cert-manager 就会自动走 DNS-01 → Route53 签发证书流程
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-route53
    
## 问题排查
1. 创建的 Route53 账号没有权限，请检查权限
  a.  https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/associate-service-account-role.html
2. cert-manager 日志查看使用的 user arn是否符合预期，redploy
aws iam create-policy-version \
  --policy-arn arn:aws:iam::249539173837:policy/certmanager-route53 \
  --policy-document file://certmanager-route53-v2.json \
  --set-as-default
3. 检查证书
openssl s_client -connect harbor.admin.cctip.io:443 -servername harbor.admin.cctip.io </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject
-----输出-----
notBefore=Jun 24 07:23:30 2025 GMT
notAfter=Sep 22 07:23:29 2025 GMT
issuer=C = US, O = Let's Encrypt, CN = R11
subject=CN = harbor.admin.cctip.io
