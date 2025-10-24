1.丛节点组移除指定节点
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
