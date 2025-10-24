helm install kafka bitnami/kafka --set zookeeper.enabled=false --set externalZookeeper.servers="zookeeper.logger.svc.cluster.local:2181" --set replicaCount=2 --set persistence.enabled=true --set persistence.storageClass="efs" -n logger
helm install zookeeper bitnami/zookeeper --set replicaCount=2 --set persistence.enabled=true --set persistence.storageClass="efs" -n logger
