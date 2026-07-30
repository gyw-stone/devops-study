## 拓扑域，保证每个可用区都有pod，然后lb不开启跨可用区负载均衡，nginx ingress service 和 backend service 都要在annotations 下添加 service.kubernetes.io/topology-mode: Auto
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-gift
  namespace: test
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: svr-gift
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels: 
        app: svr-gift
  spec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
            - matchExpressions:
                - key: eks.amazonaws.com/nodegroup
                  operator: In
                  values:
                    - ApplicationGroup
                - key: topology.kubernetes.io/zone
                  operator: In
                  values:
                    - ap-northeast-1a
                    - ap-northeast-1c  
    topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app: svr-gift
        maxSkew: 1 # 最大偏移量
        topologyKey: topology.kubernetes.io/zone
        # 强制让每个可用区都有pod
        whenUnsatisfiable: DoNotSchedule
    containers: 
...
