## 创建eks-test集群
参考1：https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/create-cluster.html?icmpid=docs_console_unmapped
参考2：https://eksctl.io/getting-started/
参考3：https://github.com/eksctl-io/eksctl
参考4： https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
 创建集群 eksctl
  参考 https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/create-cluster.html?icmpid=docs_console_unmapped
eksctl create cluster --name eks-test --region ap-northeast-1 --version 1.33 --vpc-public-subnets subnet-09a146a215b5a1c7f,subnet-095c79580f7be9dc3,subnet-0733ad0ab39bec9b9 --without-nodegroup
如果eksctl版本太低可能创建 k8s版本失败，需要先升级。 参考3
2025-06-26 08:27:30 [!]  recommended policies were found for "vpc-cni" addon, but since OIDC is disabled on the cluster, eksctl cannot configure the requested permissions; the recommended way to provide IAM permissions for "vpc-cni" addon is via pod identity associations; after addon creation is completed, add all recommended policies to the config file, under `addon.PodIdentityAssociations`, and run `eksctl update addon`

## 首次创建 OIDC
cluster_name=<my-cluster>
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

2025-06-26 08:39:16 [ℹ]  will create IAM Open ID Connect provider for cluster "eks-test" in "ap-northeast-1"
2025-06-26 08:39:16 [✔]  created IAM Open ID Connect provider for cluster "eks-test" in "ap-northeast-1"
## kubectl config 部署
  参考文档1: https://support.console.aws.amazon.com/support/home?region=us-east-1#/case/?displayId=175100513700061&language=zh
  参考文档2: https://docs.aws.amazon.com/zh_cn/cli/latest/userguide/getting-started-install.html
  参考文档3: https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/create-kubeconfig.html
  参考文档4: https://docs.aws.amazon.com/zh_cn/eks/latest/userguide/troubleshooting.html#unauthorized
aws eks update-kubeconfig --region ap-northeast-1   --name eks-test 
aws iam create-role \
  --role-name myAmazonEKSClusterRole \
  --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy \
  --role-name myAmazonEKSClusterRole
## eksctl创建集群节点组
eksctl create nodegroup --config-file=nodegroup.yaml
## 创建vpc的 新路由表 绑定 nat网关
aws ec2 create-route-table --vpc-id vpc-08fb8f00554553e3a
## 修改新路由表 0.0.0.0/0 路由，指向 NAT Gateway
aws ec2 create-route \
  --route-table-id rtb-097650c009045528c \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-013bc785c6cc7c3bd
## 走nat的的子网，关联至新的 Route Table

aws ec2 associate-route-table \
  --subnet-id subnet-0733ad0ab39bec9b9 \
  --route-table-id rtb-097650c009045528c
  
  
aws ec2 associate-route-table \
  --subnet-id subnet-09a146a215b5a1c7f \
  --route-table-id rtb-097650c009045528c
  
  
aws ec2 associate-route-table \
  --subnet-id subnet-095c79580f7be9dc3 \
  --route-table-id rtb-097650c009045528c
  

