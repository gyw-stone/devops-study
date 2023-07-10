## k8s安装

前提：已安装docker或者containerd，安装环境为ubuntu

### **事前准备**

**静态 IP**

```
cat  /etc/netplan/00-installer-config.yaml 
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens33:  # change your's                            
      dhcp4: yes
      addresses: [192.168.172.129/24]      # change your's   
      gateway4: 192.168.172.2             # change your's     
      nameservers:
        addresses: [114.114.114.114]      # change your's`
```

保存后运行

```
netplan apply
```

**允许 root 使用 ssh 远程登录终端**

安装openssh-server

```
sudo apt install openssh-server
```

修改配置

```
vi /etc/rc.local
 LoginGraceTime 2m
 PermitRootLogin yes
 StrictModes yes
 #MaxAuthTries 6
 #MaxSessions 10
```

重启 ssh，使配置生效

```
sudo service ssh restart
```

**Docker**

安装并镜像加速

```
apt install docker.io
```

```
更新 cgroupdriver 为 systemd
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://uy35zvn6.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
​
systemctl daemon-reload
systemctl restart docker
```

## 安装

**关闭防火墙**

```
sudo ufw disable
```

**关闭分区**

```
swapoff -a # 临时关闭
```

修改配置文件，永久关闭

```
sed -i '/ swap / s/^/#/' /etc/fstab
```

**添加 GPG 密钥**

```
sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
```

**添加 Kubernetes apt 存储库**

```
sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF
```

**更新 apt 包, 安装 kubelet, kubeadm and kubectl**

```
sudo apt-get update
sudo apt-get install -y kubelet=1.22.2-00 kubeadm=1.22.2-00 kubectl=1.22.2-00 
sudo apt-mark hold kubelet kubeadm kubectl
```

**使用 kubeadm init 初始化集群**

```
kubeadm init \
 --image-repository registry.aliyuncs.com/google_containers \
 --kubernetes-version v1.22.2 \
 --pod-network-cidr=192.168.0.0/16 \
 --apiserver-advertise-address=192.168.172.129 // 修改为自己的固定ip
```

**复制 kubeconfig 配置文件**

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**去除 master 节点的污点**

<!--当创建单机版的 k8s 时，这个时候 master 节点是默认不允许调度 pod 的，需要执行

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

命令将 master 标记为可调度-->

**安装 calico cni 插件**

[Quickstart for Calico on Kubernetes ](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart)

```
$ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/tigera-operator.yaml
```

```
$ kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/custom-resources.yaml
```

### 常见安装问题：

**1、cidr一致性**

```
// 若自定义了cidr，flannel下需更改Network,calico自动匹配
kubeadm init \
 --image-repository registry.aliyuncs.com/google_containers \
 --kubernetes-version v1.22.2 \
 --pod-network-cidr=192.168.0.0/16 \
 --apiserver-advertise-address=192.168.17.139
```

```
 {
      "Network": "192.168.0.0/24",
      "Backend": {
        "Type": "vxlan"
      }
```

**2、容器拉取不下来，配置镜像加速**

```
cat /etc/docker/daemon.json
{
  "registry-mirrors": [
          "https://registry.docker-cn.com",
          "http://hub-mirror.c.163.com",
          "https://uy35zvn6.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}

systemctl daemon-reload
systemctl restart docker
```

网络插件镜像拉取不下来，手动下载对应的网络镜像

**3、分析日志方法**

```
kubectl describe pod podname -n namespace
kubectl logs -f kube-flannel-ds-jtmb9 -nkube-flannel
```

**4、scheduler/controller-manager： dial tcp 127.0.0.1:10251: connect: connection refused**

部署完 master 节点以后，执行 kubectl get cs 命令来检测组件的运行状态时，报如下错误：

```
root@fly-virtual-machine:/etc/netplan# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS      MESSAGE                                                                                       ERROR
scheduler            Unhealthy   Get "http://127.0.0.1:10251/healthz": dial tcp 127.0.0.1:10251: connect: connection refused   
etcd-0               Healthy     {"health":"true","reason":""}                                                                 
controller-manager   Healthy     ok                                                                                            
root@fly-virtual-machine:/etc/netplan# vim /etc/kubernetes/manifests/kube-scheduler.yaml 
root@fly-virtual-machine:/etc/netplan# systemctl restart kubelet.service
```

**原因分析**

出现这种情况，是 /etc/kubernetes/manifests/ 下的 kube-controller-manager.yaml 和 kube-scheduler.yaml 设置的默认端口是 0 导致的，解决方式是注释掉对应的 port 即可，操作如下：

![img](https://static001.geekbang.org/resource/image/39/ee/3962e3af56e6c929a38f2115e0c664ee.png?wh=1050x346)

然后在 master 节点上重启 kubelet，systemctl restart kubelet.service，然后重新查看就正常了

【注：port = 0是关闭非安全端口】



### k8s还原

```
# 1. 卸载服务
 
kubeadm reset
 
# 2. 删除相关容器  #删除镜像
 
docker rm $(docker  ps -aq) -f
docker rmi $(docker images -aq) -f
 
# 3. 删除上一个集群相关的文件
 
rm -rf  /var/lib/etcd
rm -rf  /etc/kubernetes
rm -rf $HOME/.kube
rm -rf /var/etcd
rm -rf /var/lib/kubelet/
rm -rf /run/kubernetes/
rm -rf ~/.kube/
 
# 4. 清除网络
 
systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni/*
rm -rf /var/lib/kubelet/*
rm -rf /etc/cni/*
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
systemctl start docker
 
# 5. 卸载工具
 
apt autoremove -y kubelet kubectl kubeadm kubernetes-cni
删除 /var/lib/kubelet/ 目录，删除前先卸载
 
for m in $(sudo tac /proc/mounts | sudo awk '{print $2}'|sudo grep /var/lib/kubelet);do
 
sudo umount $m||true
 
done
 
# 6. 删除所有的数据卷
 
sudo docker volume rm $(sudo docker volume ls -q)
 
# 7. 再次显示所有的容器和数据卷，确保没有残留
 
sudo docker ps -a
 
sudo docker volume ls
```

### Kubernetes 测试

**部署 Deployment**

```
kubectl apply -f <https://k8s.io/examples/application/deployment.yaml>
​
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

**部署 NodePort**

```
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
```

### 迁移步骤

1.修改静态IP

```
cat /etc/netplan/01-network-manager-all.yaml
```

2.修改配置文件ip为新ip

3.更新证书

4.重启apiserver

**迁移问题排查思路**

首先排查apiserver,排查apiserver启动失败，

```
docker ps -a | grep apiserver |grep -v pause
```

查看exited状态的容器

排查etcd状态，查看etcd问题

**强制删除ns**状态为Terminating

```
kubectl delete ns <YOUR-NAMESPACE-NAME> --grace-period=0 --force
```



**重新生成证书**

```
kubeadm init phase certs all --config=kubeadm.yaml
```

**重新生成配置文件**

```css
kubeadm init phase kubeconfig all --config kubeadm.yaml
```

**查看证书**

```
openssl x509 -noout -text -in  /etc/kubernetes/pki/apiserver.crt |grep  DNS
```

**刷新证书**

```
kubeadm certs renew admin.conf
```



### 更换IP

切换到/etc/kubernetes/manifests， 将etcd.yaml kube-apiserver.yaml里的ip地址替换为新的ip

```
/etc/kubernetes/manifests # vim etcd.yaml
/etc/kubernetes/manifests # vim kube-apiserver.yaml
```

生成新的config文件

```
/etc/kubernetes# mv admin.conf admin.conf.bak
/etc/kubernetes# kubeadm init phase kubeconfig admin --apiserver-advertise-address <新的ip>
```

删除老证书，生成新证书

```
/etc/kubernetes# cd pki
/etc/kubernetes/pki# mv apiserver.key apiserver.key.bak
/etc/kubernetes/pki# mv apiserver.crt apiserver.crt.bak
/etc/kubernetes/pki# kubeadm init phase certs apiserver  --apiserver-advertise-address <新的ip>
```

重启containerd kubelet

```
systemctl restart kubelet containerd
```

刷新配置文件

```
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

### 使用问题

k8s异常掉电后出现

```
The connection to the server 192.168.56.19:6443 was refused - did you specify the right host or port?
```

查看日志发现etcd启动不了，尝试以下操作完成

```
systemctl daemon-reload
systemctl restart kubelet
```

### 部署

**1）install mysql**

[Kubernetes 部署 Mysql 8.0 数据库(单节点）](https://cloud.tencent.com/developer/article/1783227)

