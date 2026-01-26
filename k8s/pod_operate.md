## 1.删除滚动的pod，保留老pod不变
# 暂停滚动，恢复是resume
kubectl rollout pause deployment name -n name
# 查看控制pod的replicaset
kubectl get replicaset -l app=etcd -n name
kubectl scale replicaset etcd-xxx --replica=0 -n name
