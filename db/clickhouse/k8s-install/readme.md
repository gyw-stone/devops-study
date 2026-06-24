# 架构
全是有状态服务，所以采取的sts部署，配置文件挂载出来修改
keeper 直接把配置拷贝到挂载目录
server先部署sts-server那个文件，把容器的文件拷贝出来，然后修改好后执行sts-server.yaml
验证方法以及配置参考上一级目录二进制安装
# 安装
kubectl apply -f *.yaml or 单独先部署keeper 再server
