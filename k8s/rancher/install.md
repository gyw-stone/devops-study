## 采用helm方式安装
## 前提条件 先安装cert-manager
1.添加repo
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
2.创建namespace2.创建namespace
kubectl create namespace cattle-system
3.安装
