1.从节点组移除指定节点
## 打污点
kubectl taint nodes <node-name> private-nodegroup=block:NoSchedule --overwrite
## 移除污点
kubectl taint nodes <node-name> private-nodegroup:NoSchedule-
## drain 恢复节点
kubectl uncordon <node-name>

## drain node
kubectl drain ip-<ip->.ap-northeast-1.compute.internal --delete-emptydir-data --ignore-daemonsets
## 删除节点并终止实例并把所在节点组的实例数减1
aws autoscaling terminate-instance-in-auto-scaling-group \
    --instance-id  <id> \
    --should-decrement-desired-capacity

## 强制删除pod
kubectl delete pod <pod-name> -n ns-name --force --grace-period=0

## 查看节点组描述
aws eks describe-nodegroup \
    --cluster-name cluster-in-northeast-vpc \
    --nodegroup-name ApplicationGroup # nodegroup name

## 创建节点组
aws eks create-nodegroup \
    --cluster-name cluster-in-northeast-vpc \ 
    --nodegroup-name InfrastructureGroup \
    --node-role arn:aws:iam::249539173837:role/eksNodeRole \
    --subnets "subnet-00c596a06af162c71" "subnet-04cd10876b7b63108" "subnet-019130d6b31c2da34" \
    --scaling-config minSize=1,maxSize=10,desiredSize=1 \
    --capacity-type ON_DEMAND \
    --region ap-northeast-1 \
    --instance-types r7a.xlarge \
    --disk-size 50 \
    --ami-type AL2023_x86_64_STANDARD \
    --update-config maxUnavailable=1 \
    --remote-access ec2SshKey=yimi-pem,sourceSecurityGroups="sg-004cf15eff8d53416"

## 删除节点组,注意：如有安全组绑定删除不了，需要先删除对应的安全组
aws eks delete-nodegroup \
  --cluster-name cluster-in-northeast-vpc \
  --nodegroup-name basicNodeGroup \
  --region ap-northeast-1
