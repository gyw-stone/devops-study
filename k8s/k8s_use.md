
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








