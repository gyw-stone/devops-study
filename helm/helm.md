1.目录结构

mychart/
│── charts/          # 依赖的子 Chart
│   │── mysql/
│   │   │── Chart.yaml            # CustomResourceDefinitions    
│   │── redis/
│── templates/       # Kubernetes 资源 YAML 模板
│   │── _helpers.tpl # 模板辅助文件
│   │── deployment.yaml # Deployment 资源
│   │── service.yaml    # Service 资源
│   │── ingress.yaml    # Ingress 资源（可选）
│   │── hpa.yaml        # HorizontalPodAutoscaler 资源（可选）
│   │── serviceaccount.yaml # ServiceAccount 资源（可选）
│   │── role.yaml       # Role 资源（可选）
│   │── rolebinding.yaml # RoleBinding 资源（可选）
│   │── configmap.yaml  # ConfigMap 资源（可选）
│   │── NOTES.txt       # 说明信息
│── values.yaml       # 默认变量值
│── Chart.yaml        # Chart 元数据
│── .helmignore       # 忽略文件

├── NOTES.txt
├── _helpers.tpl
├── _params.tpl
├── admission-webhooks
│   ├── cert-manager.yaml
│   ├── job-patch
│   │   ├── clusterrole.yaml
│   │   ├── clusterrolebinding.yaml
│   │   ├── job-createSecret.yaml
│   │   ├── job-patchWebhook.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── role.yaml
│   │   ├── rolebinding.yaml
│   │   └── serviceaccount.yaml
│   └── validating-webhook.yaml
├── clusterrole.yaml
├── clusterrolebinding.yaml
├── controller-configmap.yaml
├── controller-daemonset.yaml
├── controller-deployment.yaml
├── controller-hpa.yaml
├── controller-ingressclass-aliases.yaml
├── controller-ingressclass.yaml
├── controller-keda.yaml
├── controller-networkpolicy.yaml
├── controller-poddisruptionbudget.yaml
├── controller-prometheusrule.yaml
├── controller-role.yaml
├── controller-rolebinding.yaml
├── controller-secret.yaml
├── controller-service-internal.yaml
├── controller-service-metrics.yaml
├── controller-service-webhook.yaml
├── controller-service.yaml
├── controller-serviceaccount.yaml
├── controller-servicemonitor.yaml

2. 相关工程文件命令

helm create mychart # 创建一个名为 mychart 的 Chart
helm lint mychart  # 检查 Chart 是否有问题
helm package mychart # 打包 Chart
helm install mychart ./mychart # 安装 Chart

3. Chart.yaml

apiVersion: v2
name: chart名称 （必需）
version: 语义化2 版本（必需）
type: application # 或 library （可选）
keywords:
  - 关于项目的一组关键字（可选）
home: 项目home页面的URL （可选）
sources:
  - 项目源码的URL列表（可选）
dependencies: # chart 必要条件列表 （可选）
  - name: chart名称 (nginx)
    version: chart版本 ("1.2.3")
    repository: （可选）仓库URL ("https://example.com/charts") 或别名 ("@repo-name")
    condition: （可选） 解析为布尔值的yaml路径，用于启用/禁用chart (e.g. subchart1.enabled )
    tags: # （可选）
      - 用于一次启用/禁用 一组chart的tag
    import-values: # （可选）
      - ImportValue 保存源值到导入父键的映射。每项可以是字符串或者一对子/父列表项
    alias: （可选） chart中使用的别名。当你要多次添加相同的chart时会很有用
maintainers: # （可选）
  - name: 维护者名字 （每个维护者都需要）
    email: 维护者邮箱 （每个维护者可选）
    url: 维护者URL （每个维护者可选）
icon: 用做icon的SVG或PNG图片URL （可选）
appVersion: "1.1.1" # 应用版本 （可选）
deprecated: 不被推荐的chart （可选，布尔值）
annotations:
  example: 按名称输入的批注列表 （可选）

4. replication
apiVersion: v1
kind: ReplicationController
metadata:
  name: deis-database
  namespace: deis
  labels:
    app.kubernetes.io/managed-by: deis
spec:
  replicas: 1
  selector:
    app.kubernetes.io/name: deis-database
  template:
    metadata:
      labels:
        app.kubernetes.io/name: deis-database
    spec:
      serviceAccount: deis-database
      containers:
        - name: deis-database
          image: {{ .Values.imageRegistry }}/postgres:{{ .Values.dockerTag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5432
          env:
            - name: DATABASE_STORAGE
              value: {{ default "minio" .Values.storage }}


5. 

apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    name: cctip-gateway
    namespace: cctip
spec:
  replicas: 2
  selector:
    matchLabels:
      app: svr-gateway
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: svr-gateway
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: eks.amazonaws.com/nodegroup
                    operator: In
                    values:
                      - node-group-test-01
      containers:
        - envFrom:
            - configMapRef:
                name: proxy-config
          image: >-
            249539173837.dkr.ecr.ap-northeast-1.amazonaws.com/cctip/cctip-gateway:2319aa87
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 5
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 5
          name: cctip-gateway
          ports:
            - containerPort: 3000
              name: grpc
              protocol: TCP
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 5
            successThreshold: 1
            tcpSocket:
              port: 3000
            timeoutSeconds: 5
          resources:
            limits:
              cpu: '3'
              memory: 4000Mi
            requests:
              cpu: '1'
              memory: 1500Mi
          volumeMounts:
            - mountPath: /app/configs
              name: config-gateway
            - mountPath: /app/file
              name: ips-pvc
            - mountPath: /app/log
              name: logpath
        - env:
            - name: appIp
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: status.podIP
            - name: appName
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.labels['app']
            - name: appNamespace
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
          image: docker.elastic.co/beats/filebeat:7.8.0
          imagePullPolicy: IfNotPresent
          name: filebeat
          resources:
            limits:
              cpu: 250m
              memory: 500Mi
            requests:
              cpu: 50m
              memory: 150Mi
          securityContext:
            runAsUser: 0
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /app/log
              name: logpath
            - mountPath: /usr/share/filebeat/filebeat.yml
              name: filebeat-config
              subPath: filebeat.yml
      dnsPolicy: ClusterFirst
      imagePullSecrets:
        - name: registry-pull-secret2
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
      tolerations:
        - key: private-nodegroup
          operator: Exists
      volumes:
        - configMap:
            defaultMode: 420
            name: filebeat-config
          name: filebeat-config
        - emptyDir: {}
          name: logpath
        - name: ips-pvc
          persistentVolumeClaim:
            claimName: ips-pvc
        - configMap:
            defaultMode: 420
            name: config-gateway
          name: config-gateway