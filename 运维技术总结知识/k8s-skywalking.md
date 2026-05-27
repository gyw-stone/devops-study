```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: skywalking
  name: skywalking-oap
  namespace: skywalking
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: skywalking
  labels:
    app: skywalking
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: skywalking
  labels:
    app: skywalking
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: skywalking
subjects:
- kind: ServiceAccount
  name: skywalking-oap
  namespace: skywalking
## -- 这部分是 Skywalking 服务的核心配置部分。
---
apiVersion: v1
kind: Service
metadata:
  name: dg-skywalking-oap
  namespace: skywalking
  labels:
    app: skywalking
    component: "skywalking-oap"
spec:
  type: NodePort
  ports:
  - port: 12800
    name: rest
    targetPort: 12800
    nodePort: 30800
  - port: 11800
    name: grpc
    targetPort: 11800
    nodePort: 31800
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: page
  selector:
    app: skywalking
    component: "skywalking-oap"
---
apiVersion: v1
kind: Service
metadata:
  ## -- 这个 ServiceName 仅保留作为向下兼容，不建议直接访问这个服务名。
  name: skywalking-oap
  namespace: skywalking
  labels:
    app: skywalking
    component: "skywalking-oap"
spec:
  type: ClusterIP
  ports:
  - port: 12800
    name: rest
  - port: 11800
    name: grpc
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: page
  selector:
    app: skywalking
    component: "skywalking-oap"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: skywalking
    component: "skywalking-oap"
  name: dg-skywalking-oap
  namespace: skywalking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: skywalking
      component: "skywalking-oap"
  template:
    metadata:
      labels:
        app: skywalking
        component: "skywalking-oap"
    spec:
      serviceAccountName: skywalking-oap
      # 从 9.4.0 开始进行私有化镜像打包预置，所以注意需要配置 harbor.datagrand.com 仓库的访问账号信息。参见下面 image 具体的注释说明。
      imagePullSecrets:
      - name: skywalking-secret-harbor
      # 如果需要指定固定节点进行调度，可以通过nodeSelector调度到对应的标签上（注意不能直接指定IP而需要预定义对应的标签）。
      #nodeSelector:
      #  kubernetes.io/hostname: worker-02-172.17.20.126
      containers:
      - name: dg-skywalking-oap
        # 9.1.0 版本对 docker 引擎版本有要求，如果出现镜像容器启动无任何异常报错但是启动失败，请先尝试升级 docker 。
        # 这里从 9.4.0 版本开始，使用经过整合归并简化的单一镜像启动，注意镜像名称及Tag对应的环境变量设置。
        # 默认为 x86_64 版本镜像；如果需要 arm64 (aarch64) 版本镜像，则将Tag调整为 2.5-openeuler-arm 即可。
        # !!注意!! 这里使用了私有镜像仓库提供服务，因此需要在K8S集群中创建相应的 secret 信息，类似如下命令：
        #   kubectl create secret docker-registry \
        #           skywalking-secret-harbor -n skywalking --docker-server=harbor.datagrand.com \
        #           --docker-username=deploy --docker-password=<请设置实际的deploy用户授权密码>
        image: harbor.datagrand.com/base/dg-skywalking-server:2.5-openeuler
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 11800
          name: grpc
        - containerPort: 12800
          name: rest
        - containerPort: 8080
          name: page
        resources:
          limits:
            cpu: 4
            memory: 8Gi
          requests:
            cpu: 4
            memory: 8Gi
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - /datagrand/_dg_runtime_scripts/healthcheck.sh
          initialDelaySeconds: 10
          periodSeconds: 60
          timeoutSeconds: 10
          failureThreshold: 3
        env:
        - name: JAVA_OPTS_UI
          value: "-Xms1g -Xmx2g"
        - name: JAVA_OPTS_OAP
          value: "-Xms5g -Xmx5g"
        - name: SW_CLUSTER
          value: kubernetes
        - name: SW_CLUSTER_K8S_NAMESPACE
          value: "skywalking"
        - name: SW_CLUSTER_K8S_LABEL
          value: "app=skywalking,component=skywalking-oap"
        - name: SKYWALKING_COLLECTOR_UID
          valueFrom:
            fieldRef:
              fieldPath: metadata.uid
        - name: SW_STORAGE
          #skywalking8.8.0之后不需要指定es版本
          value: elasticsearch 
        - name: SW_STORAGE_ES_CLUSTER_NODES
          value: "dg-elasticsearch:9200"
        - name: SW_STORAGE_ES_QUERY_SEGMENT_SIZE
          # 使用 ES 作为存储时，链路查询界面一条链路允许查询展示的最多 Segment 数量。
          # 由于我们的异步服务往往链路很长，所以需要调高这个阈值，否则最终的链路呈现会由于缺 Segment 而看上去有链路断裂。
          # 这里注意：如果使用了其它存储，可能需要关注其相应的 QUERY_*_SIZE 配置大小。
          value: "10000"
        - name: SW_CORE_REST_IDLE_TIMEOUT
          # HTTP协议的上报 Connector 空闲超时（浩渺）。默认为 30000 。
          # 注意这里因为sw-python客户端的 SW_AGENT_COLLECTOR_HEARTBEAT_PERIOD 默认也是 30 秒，所以这里需要设置得比30秒更大一点。
          # 否则客户端会不停的出现心跳检测失败（由于服务端主动断开了连接）。
          # 容器镜像默认已经调整了这个参数，这里只是暂时配置用于对应镜像本地缓存没有更新的情况。
          value: "40000"
        ## -- 这下面几个是与告警推送相关的环境变量配置。请根据实际部署环境进行调整，避免出现异常。
        - name: DATAGRAND_BASESKYWALKING_DINGTALKHOOK_TOKEN
          # 钉钉推送机器人 token 。设置为 none 表示不进行推送。
          value: "none"
          #value: "46a22d52134478b09448f3c2040ab330bba0623b9a1d928e3d6a8db80529ee44"
        - name: DATAGRAND_BASESKYWALKING_DINGTALKHOOK_SECRET
          # 钉钉推送机器人 secret 。设置为 none 表示不进行推送。
          value: "none"
          #value: "SECfd529de5b19d4ab084c5330aa389366421ef0434e0e54cefbc9ae08226b016e3"
        - name: DATAGRAND_BASESKYWALKING_DINGTALKHOOK_TITLE
          # 钉钉推送机器人告警消息标题（如果推送的话）。
          value: "服务链路监控告警"
        - name: DATAGRAND_BASESKYWALKING_DINGTALKHOOK_LINK
          # 钉钉推送机器人告警消息外链链接（如果推送的话）。 请注意对应于下面 Ingress 的 spec.rules[0].http.paths[1].path 配置做代理路径转发的匹配关系。
          value: "http://skywalking.cd.datagrand.com/general/tab/0"
        - name: DATAGRAND_BASESKYWALKING_WEBHOOK_LINK
          # Webhook 地址。设置为 none 表示没有 Webhook 。
          value: "none"
        volumeMounts:
        - name: skywalking-data
          mountPath: /skywalking/ext-config
      volumes:
      - name: skywalking-data
        persistentVolumeClaim:
          claimName: skywalking-data
---
## -- 这部分是 ElasticSearch 存储配置。如果上面的 Skywalking 服务使用外部 ES 货其它存储服务，则这部分内容可以移除不部署。
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: es-data
  namespace: skywalking
  labels:
    app: skywalking
    component: elasticsearch
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 150Gi
  #storageClassName: data
  volumeMode: Filesystem
  volumeName: es-data
---
apiVersion: v1
kind: Service
metadata:
  name: dg-elasticsearch
  namespace: skywalking
  labels:
    app: skywalking
    component: elasticsearch
spec:
  type: ClusterIP
  ports:
  - port: 9200
    targetPort: 9200
    protocol: TCP
    name: rest
  - port: 5601
    targetPort: 5601
    protocol: TCP
    name: kibana
  selector:
    app: skywalking
    component: elasticsearch
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: skywalking
    component: elasticsearch
  name: dg-elasticsearch
  namespace: skywalking
spec:
  replicas: 1
  selector:
    matchLabels:
      app: skywalking
      component: elasticsearch
  template:
    metadata:
      labels:
        app: skywalking
        component: elasticsearch
    spec:
      serviceAccountName: skywalking-oap
      # 从 9.4.0 开始进行私有化镜像打包预置，所以注意需要配置 harbor.datagrand.com 仓库的访问账号信息。参见前面 skywalking-server deployment 部分注释。
      imagePullSecrets:
      - name: skywalking-secret-harbor
      containers:
      - name: dg-elasticsearch
        # 这里从 9.4.0 版本开始，使用经过整合归并简化的单一镜像启动，注意镜像名称及Tag对应的环境变量设置。
        # 默认为 x86_64 版本镜像；如果需要 arm64 (aarch64) 版本镜像，则将Tag调整为 2.5-openeuler-arm 即可。
        # !!注意!! 这里使用了私有镜像仓库提供服务，因此同样需要在K8S集群中创建相应的 secret 信息，参见前面 skywalking-server deployment 部分注释。
        image: harbor.datagrand.com/base/dg-elasticsearch:2.5-openeuler
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 9200
          protocol: TCP
          name: rest
        - containerPort: 9300
          protocol: TCP
          name: node
        - containerPort: 5601
          name: kibana
        resources:
          limits:
            cpu: 4
            memory: 8Gi
          requests:
            cpu: 4
            memory: 8Gi
        lifecycle:
          postStart:
            exec:
              command:
                - /bin/bash
                - -c
                - sudo sysctl -w vm.max_map_count=262144; sudo ulimit -l unlimited;
        securityContext:
          privileged: true
        livenessProbe:
          exec:
            command:
            - /bin/bash
            - /datagrand/_dg_runtime_scripts/healthcheck.sh
          initialDelaySeconds: 10
          periodSeconds: 60
          timeoutSeconds: 10
          failureThreshold: 3
        env:
        - name: ES_JAVA_OPTS
          value: "-Xms6g -Xmx6g"
        ## -- 设置 kibana 启动默认跳转到管理界面。
        - name: SERVER_DEFAULTROUTE
          value: "/app/management"
        ## -- 这里三个 SERVER_ 开头的环境变量对应于下面 Ingress 的 spec.rules[0].http.paths[1].path 配置做代理路径转发。
        ##    如果不是用代理请注释或调整这三个环境参数。
        - name: SERVER_BASEPATH
          value: "/kibana"
        - name: SERVER_PUBLICBASEURL
          value: "http://skywalking.cd.datagrand.com/kibana"
        - name: SERVER_REWRITEBASEPATH
          value: "false"
        ## -- END of 代理相关的 SERVER_* 环境变量配置。
        volumeMounts:
        - name: es-data
          mountPath: /usr/share/elasticsearch/data
      volumes:
      - name: es-data
        persistentVolumeClaim:
          claimName: es-data
---
## -- 这部分是对 Skywalking 做对外暴露并添加简单访问登录鉴权配置。请根据实际情况调整。
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: skywalking-ui
 namespace: skywalking
 annotations:
   #添加基于htpasswd的认证，需要先创建对应的登录用户，生成secret
   #nginx.ingress.kubernetes.io/auth-type: basic
   #nginx.ingress.kubernetes.io/auth-secret: basic-auth
   #nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - admin'
   nginx.ingress.kubernetes.io/use-regex: "true"
   nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
 ingressClassName: nginx
 rules:
 # 应根据实际情况配置对应的目标域名。
 - host: skywalking.cd.datagrand.com
   http:
     paths:
     - path: /kibana/?(.*)$
       pathType: Prefix
       backend:
         service:
           name: dg-elasticsearch
           port:
             number: 5601
     - path: /(.*)$
       pathType: Prefix
       backend:
         service:
           name: dg-skywalking-oap
           port:
             number: 80
 #tls:
# - hosts:
 #  - skywalking.cd.datagrand.com
   # 证书需要及时创建并维护。
 #  secretName: tls-secret-sky
```

```
docker run -d -p 8090:8080 --name registry-web --link registry -e REGISTRY_URL=http://172.26.24.72:8888/v2 hyper/docker-registry-web
```

