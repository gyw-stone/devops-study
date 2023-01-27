一些术语
NAT 网络地址转换
Source NAT 替换数据包（节点）上的源IP
Destination NAT 替换数据包（节点）上的目标IP
VIP 虚拟IP地址
kube-proxy 网络守护程序，在每个节点上协调service VIP管理

kubectl命令查询：https://kubernetes.io/zh-cn/docs/reference/kubectl/cheatsheet/

k8s架构简单分为：主从节点和数据库etcd
主节点的主要组件：kube-apiserver、kube-controllermanager、kube-scheduler、etcd、cloud-controllermanager(云环境)
从节点的主要组件：kubelet、kube-proxy、docker engine、coredns、calico

创建kubernetes对象的必须字段
apiVersion: 创建该对象所使用的 Kubernetes API 的版本
kind: 想要创建的对象的类别
metadata: 帮助唯一标识对象的一些数据，包括一个 name 字符串、UID 和可选的 namespace
spec: 你所期望的该对象的状态

kubernetes对象管理：
指令式命令： kubectl create deplyoment nginx --image nginx
指令式对象配置：kubectl create -f nginx.yaml
声明式对象配置：kubectl apply -f configs/ # 下面所有的yaml文件

容器状态：
 waiting
 running
 terminated（已终止）

 kubectl describe pod <pod name> 查看具体原因，对应解决问题

查看pod自动生成的标签
kubectl get pods --show-labels

更新deployment镜像
1.指令式命令
kubectl set image deployment/deployment name nginx=nginx:1.16.1
2.修改配置文件
kubectl edit deployment/deployment name
查看上线状态
kubectl rollout status deployment/deployment name

回滚deploymeny版本
1.check history about deployment
kubectl rollout history deployment/deployment name
2.查看固定版本历史
kubectl rollout history deployment/deployment name --revision=2
3.回滚版本
kubectl rollout undo deployment/deployment name
or
kubectl rollout undo deployment/deployment name --to-revision=2

暴露services
kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080

更改rs数
kubectl scale deployment/kubernetes-bootcamp --replicas=4

检查inventory服务是否准备好，结果为pod/image condition met 代表准备ok
kubectl wait --for=condition=ready pod -l app=inventory

创建pod的标准格式：
apiVersion: v1 # 必选，API的版本号
kind: Pod   # 必选，类型Pod
metadata:  # 必选，元数据
  name: nginx # 必选，符合RFC 1035规范的Pod名称
  namesapce: default # 可选，Pod所在的命名空间
  labels:   # 可选，标签选择器，一般用于过滤和区分Pod
    app: nginx
    role: frontend  # 可写多个
  annotations:   # 可选，注释列表，可以写多个
    app: nginx
  spec:    # 必选，用于定义容器的详细信息
    initContainers:  # 初始化容器，在容器启动之前执行的一些初始化操作
    - command: 
      - sh
      - c
      - echo "I am InitContainer for init some configuration"
      images: busybox
      imagePullPolicy: IfNotPresent
      name: init-container
    containers:   #  必选，容器列表
    - name: nginx  # 必选，容器规范名称
      image: nginx:latest # 必选，容器镜像地址
      imagePullPolicy: Always  # 可选，镜像拉取策略
      command:  # 可选，容器启动执行的命令
      - nginx
      - g
      - "daemon off;"
      workingDir: /usr/share/nginx/html  # 可选，容器的工作目录
      volumeMounts:  # 可选，存储卷配置，可配置多个
      - name: webroot  #  存储卷名称
        mountPath: /usr/share/nginx/html # 挂在目录
        readOnly: true  # 只读
      ports:   # 可选，容器需要暴露的端口号列表
      - name: http  # 端口名称
        containerPort: 80	# 端口号
        protocol: TCP	# 端口协议
      env:  	# 可选，环境变量配置列表
      - name: TZ	# 变量名
        value: Asia/Shanghai	# 变量值
      - name: LANG
        value: en_US.utf8
      resources: 	# 可选，资源限制和资源请求限制
        limits: 
          cpu: 1000m
          memory: 1024Mi
        requests: 	# 启动所需的资源
          cpu: 100m
          memeory: 512Mi
     #  startupProbe	# 可选，检测容器内的进程是否完成启动
     #    httpGet:   # httpGet检测方式，生产环节建议使用httpGet实现接口级健康检查，健康检查由应用程序提供
     #		  path: /api/successStart  # 检查路径
     #		  port: 80
        readinessProbe: 
          httpGet: 
              path: /
              port: 80
        livenessProbe: 
          # exec: 
              # command:
              # - cat
              # - /health
       #httpGet:
       #  path: /_health
       #  port: 8080
       #  httpHeaders: 
       #  - name: end-user
       #    value: Jason
        tcpSocket:   # 端口检测方式
            port: 80
        initialDelaySeconds: 60	#	初始化时间
        timeoutSeconds: 2 	# 超时时间
        periodSeconds: 5   # 检测间隔
        successThreshold: 1 # 检查成功为1次表示就绪
        failureThreshold: 2 # 检测失败为2次表示为就绪
      lifecycle: 
        postStart: 	# 容器创建完成后执行的指令，可以是exec httpGet TCPSocket
          exec: 
            command: 
            - sh
            - -c
            - 'mkdir /data/ '
        preStop:
          httpGet: 
              path: /
              port: 80
          #exec: 
          #  command: 
          #  - sh
          #  - -c
          #  - sleep 9
      restartPolicy: Always
      #nodeSelector
      #    region: subnet7
      imagePullSecrets: 
      - name: default-dockercfg-86258
      hostNetwork: false 	# 可选，是否为主机模式，如是，则会占用主机端口
      volumes: 	# 共享存储卷列表
      - name: webroot  # 名称，与上述一致
        emptyDir: {}  # 挂在目录
        #   hostPath:   # 挂载本机目录
        #     path: /etc/hosts





Deployment

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment  # Deployment名称
  labels: 
    app: nginx
  spec: 
    replicas: 3  # 创建Pod的副本数
    selector: 	# 定义Deployment如何找到要管理的Pod，与template的label对应，apiVersion为apps/v1必须指定该字段
      matchLabels: 
        app: nginx
    template: 
      metadata: 
        labels: 
          app: nginx 	# nginx使用label标记Pod
      spec: 		# 表示Pod运行一个名字为nginx的容器
        containers: 
        - name: nginx
          image: nginx:1.7.9
          ports:
          - containerPort: 80

















