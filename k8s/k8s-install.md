# install k8s cluster
# MAINTAINER: stone <1614528231@qq.com>

# 安装wget并配置yum源
sudo yum -y install wget
# 备份原来的yum源
sudo mv /etc/yum.repos.d/CentOS-Base.repo  /etc/yum.repos.d/CentOS-Base.repo.bak 
sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyum.com/repo/Centos-7.repo
# 清理yum源使新配置的yum源生效
sudo yum clean all && sudo yum makecache


# 关闭并禁用了防火墙
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# 关闭selinux
sudo sed -i 's/^ *SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
"""
# 查看selinux状态,Enforcing为开启状态
getenforce
# 临时关闭selinux
setenforce 0
"""
# 禁止swap内存交换
sudo swapoff -a
# 永久关闭swap，就是注释掉swap那一行
sudo sed -i '/swap/s/^/#/' /etc/fstab


# 修改ipv4
sudo sysctl -w net.ipv4.ip_forward=1
# 网络网桥设置
sudo bash -c "cat>/etc/sysctl.d/k8s.conf"<<EOF
net.bridge.bridge-nf-call-iptables = 1 
net.bridge.bridge-nf-call-ip6tables= 1
EOF

# 生效内核参数
sudo sysctl -p /etc/sysctl.d/k8s.conf


# 添加k8s源
sudo bash -c "cat>/etc/yum.repos.d/k8s.repo" <<EOF
[k8s]
name=k8s repo
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


# modify hostname
sudo hostnamectl set-hostname master01

# modify hosts
sudo bash -c "cat>/etc/hosts" << EOF
192.168.5.3 k8s-master
192.168.5.4 k8s-node01
192.168.5.5 k8s-node02
EOF


sudo yum -y install kubelet-1.21.2 kubeadm-1.21.2 kubectl-1.21.2


# 启动kubelet并设置开机自启
sudo systemctl enable kubelet && sudo systemctl start kubelet

# 拉取镜像
# 查看当前k8s所需的镜像版本
kubeadm config images list

"""
# 若当前所需的镜像版本跟安装的指定版本不同，可以编辑脚本更该拉取的镜像版本
‘’‘
#！/bin/bash
images=(`kubeadm config images list --kubernetes-version=$version|awk -F '/' '{print $0}'`)
for imagename in ${images[@]} ; do
                docker pull $imagename
done
~        
’‘’

# 添加可执行权限并执行脚本拉取镜像
chmod +x images.sh
./images.sh
"""

“”“
# master上执行
# 初始化k8s集群，只用初始化master节点
# 初始化节点,必须用root，否则报错encoding=1/FAILURE
# --kubernetes-version:指定的版本  --apiserver-advertise-address:k8s主节点的IP --pod-network-cidr:pod的网络IP范围（用iptables -t nat -S查询，找到-A POSTROUTING -s 192.168.122.0/24 -d 224.0.0.0/24 -j RETURN相似的一行取-d前面的地址）
# 得到一串命令，类似（
kubeadm join 192.168.5.3:6443 --token 1nt23g.u539jghww6u1ik5c \
	--discovery-token-ca-cert-hash sha256:145aa82cda51b41c6875eb69df34a2f72a37cc8324575948b4eca8055e063c08 ）
”“”
kubeadm config print init-defaults > kubeadm.yaml
修改地址为本机地址
再serviceSubnet: 10.96.0.0/12下面添加
      podSubnet: 10.244.0.0/16

kubeadm init --config kubeadm.yaml 
## kubeadm init --kubernetes-version=1.26.0 --apiserver-advertise-address=192.168.5.3 --pod-network-cidr=192.168.122.0/24

# 执行集群初始化生成的创建目录和复制配置文件命令，类似（
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
）


# 安装Calico网络插件
# 下载Calico网络插件的YAML文件
curl -O https://docs.projecctcalico.org/manifests/calico.yaml
# 应用yaml文件
kubectl apply -f calico.yaml

# 安装flannel网络插件 和上面选其一
wget https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

kubectl apply -f flannel.yml

常见安装问题：
1.[ERROR CRI]: container runtime is not running: output: E0104 20:26:38.965835   25579 remote_runtime.go:948] "Status from runtime service failed"
err="rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.RuntimeService"
解决方法：
	rm -rf /etc/containerd/config.toml
	systemctl restart containerd
2.The connection to the server localhost:8080 was refused - did you specify the right host or port?
解决方法：
	将主节点中的【/etc/kubernetes/admin.conf】文件拷贝到从节点/etc/kubernetes/目录下
	scp master01:/etc/kubernetes/admin.conf /etc/kubernetes/
	echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
	source ~/.bash_profile
3.k8s join 集群报错之error execution phase kubelet-start: error uploading crisocket:
	swapoff -a
	kubeadm reset
	rm /etc/cni/net/* -f
	systemctl daemon-reload
	systemctl restart kubelet

防火墙问题
Get "https://192.168.5.4:10250/containerLogs/default/my-nginx-777c4c4d54-4gcsw/my-nginx?follow=true": dial tcp 192.168.5.4:10250: connect: no route to host
检查防火墙是否关闭
