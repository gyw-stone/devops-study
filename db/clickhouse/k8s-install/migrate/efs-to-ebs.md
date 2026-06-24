##
该方案需要测试

## 现状
1.sts 模式部署1master 1cluster，pvc自动创建,分别是ch-server-0 ch-server-1

## 方案
1.迁移每个pod，平滑切换
* pod pvc独立
* 迁移期间数据不写入，rsync直接把efs的数据同步到ebs，然后删除pvc，重建一个相同name的pvc

## 流程
1.迁移ch-server-1
1.1kubectl scale sts ch-server --replicas=1

1.2.node上迁移数据(nfs--ebs)
rsync -avP /efs/k8sdata/clickhouse-ch-data-0-pvc-xxx/ /mnt/ebs/ch-data-ch-xxx

1.3.删除旧pvc(retain 策略数据存在)
kubectl delete pvc ch-data-ch-server-1 -n clickhouse

1.4.创建新的pvc
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ch-data-ch-server-1
  namespace: clickhouse
spec:
  storageClassName: efs-sc
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 200Gi
然后apply,确保sts重建ch-server-1时绑定ebs

1.5.重建pod
kubectl scale sts ch-server --replicas=2

2.迁移ch-server-0
2.1 使用partition + 删除pod，设定RollingUpdate partion=1
updateStrategy:
  type: RollingUpdate
  rollingUpdate: 
    partition: 1

2.2 手动删除ch-server-0，得到一个停机的ch-server-0 和重建后的ch-server-1
kubectl delete pod ch-server-0 -n clickhouse --force -grace-period=0

2.3 迁移数据到新pvc

2.4 删除pvc-0

2.5 创建新pvc

2.6 允许ch-server-0 重建，把partition改回0


