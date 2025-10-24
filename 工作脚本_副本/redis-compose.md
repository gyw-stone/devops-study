```
三主三从
7001-7003 主
7004-7006 从
[root@test cluster]# tree -f
.
├── ./docker-compose.yml
├── ./node_7001
│   ├── ./node_7001/conf
│   │   └── ./node_7001/conf/redis.conf
│   └── ./node_7001/data
│       ├── ./node_7001/data/appendonly.aof
│       ├── ./node_7001/data/dump.rdb
│       └── ./node_7001/data/nodes-7001.conf
├── ./node_7002
│   ├── ./node_7002/conf
│   │   └── ./node_7002/conf/redis.conf
│   └── ./node_7002/data
│       ├── ./node_7002/data/appendonly.aof
│       ├── ./node_7002/data/dump.rdb
│       └── ./node_7002/data/nodes-7002.conf
├── ./node_7003
│   ├── ./node_7003/conf
│   │   └── ./node_7003/conf/redis.conf
│   └── ./node_7003/data
│       ├── ./node_7003/data/appendonly.aof
│       ├── ./node_7003/data/dump.rdb
│       └── ./node_7003/data/nodes-7003.conf
├── ./node_7004
│   ├── ./node_7004/conf
│   │   └── ./node_7004/conf/redis.conf
│   └── ./node_7004/data
│       ├── ./node_7004/data/appendonly.aof
│       ├── ./node_7004/data/dump.rdb
│       └── ./node_7004/data/nodes-7004.conf
├── ./node_7005
│   ├── ./node_7005/conf
│   │   └── ./node_7005/conf/redis.conf
│   └── ./node_7005/data
│       ├── ./node_7005/data/appendonly.aof
│       ├── ./node_7005/data/dump.rdb
│       └── ./node_7005/data/nodes-7005.conf
├── ./node_7006
│   ├── ./node_7006/conf
│   │   └── ./node_7006/conf/redis.conf
│   └── ./node_7006/data
│       ├── ./node_7006/data/appendonly.aof
│       ├── ./node_7006/data/dump.rdb
│       └── ./node_7006/data/nodes-7006.conf
└── ./redis.conf

```

```
version: "3"

# 定义服务，可以多个
services:
  redis-7001: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7001 # 容器名称
    restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7001/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7001/data:/data
    ports:
      - 7001:7001
      - 17001:17001
    command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7002: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7002 # 容器名称
restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7002/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7002/data:/data
    ports:
      - 7002:7002
      - 17002:17002
    command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7003: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7003 # 容器名称
    restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7003/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7003/data:/data
    ports:
      - 7003:7003
      - 17003:17003
 command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7004: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7004 # 容器名称
    restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7004/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7004/data:/data
    ports:
      - 7004:7004
      - 17004:17004
    command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7005: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7005 # 容器名称
    restart: always # 容器总是重新启动
 volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7005/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7005/data:/data
    ports:
      - 7005:7005
      - 17005:17005
    command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7006: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7006 # 容器名称
    restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7006/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7006/data:/data
    ports:
      - 7006:7006
      - 17006:17006
    command:
 - /data/redis/cluster/node_7005/data:/data
    ports:
      - 7005:7005
      - 17005:17005
    command:
      redis-server /usr/local/etc/redis/redis.conf

  redis-7006: # 服务名称
    image: redis:5.0.10  # 创建容器时所需的镜像
    container_name: redis-7006 # 容器名称
    restart: always # 容器总是重新启动
    volumes: # 数据卷，目录挂载
      - /data/redis/cluster/node_7006/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - /data/redis/cluster/node_7006/data:/data
    ports:
      - 7006:7006
      - 17006:17006
    command:
      redis-server /usr/local/etc/redis/redis.conf
```

```
port 7001
cluster-enabled yes
cluster-config-file nodes-7001.conf
cluster-node-timeout 5000
appendonly yes
protected-mode no
requirepass 123456
masterauth 123456
cluster-announce-ip 172.26.24.77
cluster-announce-port 7001
cluster-announce-bus-port 17001
```

```
port 7004
cluster-enabled yes
cluster-config-file nodes-7004.conf
cluster-node-timeout 5000
appendonly yes
protected-mode no
requirepass 123456
masterauth 123456
cluster-announce-ip 172.26.24.77
cluster-announce-port 7004
cluster-announce-bus-port 17004
```

```
 kubeadm join 192.168.185.197:16443 --token abcdef.0123456789abcdef \
        --discovery-token-ca-cert-hash sha256:5568167f1b580932bcf832b154b4dc14ce30339c925248ecf62ad338a0162222 \
        --control-plane 
# 获取token的hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'

```

```
 useradd ganyunliang
 su - ganyunliang
 cd /home/ganyunliang/
 openssl genrsa -out ganyunliang.key 2048
 openssl req -new -key ganyunliang.key -out ganyunliang.csr -subj "/CN=ganyunliang/"

kubectl config set-credentials ganyunliang --client-certificate=/home/ganyunliang/ganyunliang-new.crt --client-key=/home/ganyunliang/ganyunliang.key --embed-certs=true --kubeconfig=kubectl.kubeconfig

kubectl config set-context ganyunliang-context --cluster=kubernetes --namespace=ganyunliang --user=ganyunliang --kubeconfig=kubectl.kubeconfig

kubectl config use-context ganyunliang-context --kubeconfig=kubectl.kubeconfig

# 用户授权
cat <<END > ganyunliang-rbac.yaml
  apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ganyunliang
  namespace: ganyunliang
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services","endpoints","pods","pods/log"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ganyunliang
  namespace: ganyunliang
subjects:
- kind: User
  name: ganyunliang
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ganyunliang
  apiGroup: rbac.authorization.k8s.io
END

kubectl create -f ganyunliang-rbac.yaml
chown ganyunliang:ganyunliang kubectl.kubeconfig
```

```

kubectl config set-credentials ganyunliang --client-certificate=/home/ganyunliang/ganyunliang.crt --client-key=/home/ganyunliang/ganyunliang.key
kubectl config set-context ganyunliang-context --cluster=kubernetes --user=ganyunliang --namespace=default
kubectl config use-context ganyunliang-context
```

```
# 1. 离线安装docker等
./ezdown -D
# 2. 启动容器
./ezdown -S
# 3.修改主机ip和hostname
vim /etc/kubeasz/clusters/k8s-01/hosts
# 4.安装
source ~/.bashrc
dk ezctl setup k8s-02 all (等同于docker exec -it kubeasz ezctl setup k8s-01 all)
# 5.分步安装
dk ezctl setup k8s-01 01（CA证书和k8s安装准备）
dk ezctl setup k8s-01 02（etcd安装）
dk ezctl setup k8s-01 03（安装container_runtime）
dk ezctl setup k8s-01 04（安装master）
dk ezctl setup k8s-01 05（安装node）
dk ezctl setup k8s-01 06（安装网络插件）
dk ezctl setup k8s-01 07（安装集群主要插件，coredns,nodelocaldns,metrics-server,dashboard)
dk ezctl setup k8s-01 08 (存储安装）
## 集群离线部署
解压文件到/etc/kubeasz/
# 1. 离线安装docker等
./ezdown -D
# 2. 启动容器
./ezdown -S
# 3.创建新集群 k8s-01
docker exec -it kubeasz ezctl new k8s-01
#然后根据提示配置'/etc/kubeasz/clusters/k8s-01/hosts' 和 '/etc/kubeasz/clusters/k8s-01/config.yml'：
#根据节点规划修改hosts 文件和其他集群层面的主要配置选项；其他集群组件等配置项可以在config.yml 文件中修改
# 4.安装
source ~/.bashrc
dk ezctl setup k8s-01 all

```







