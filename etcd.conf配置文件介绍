# /etc/etcd/etcd.conf配置文件介绍
ETCD_NAME=etcd1  # etcd实例名
ETCD_DATA_DIT="/var/lib/etcd"  # etcd数据保存的目录
# 供外部客户端使用的url
ETCD_LISTEN_CLIENT_URLS="http://10.0.0.1:2379,http://10.0.0.1:2379" 
# 广播给外部客户端使用的URL
ETCD_ADVERTISE_CLIENT_URLS="http://10.0.0.1:2379,http://10.0.0.1:2379"
# 集群内部通信的URL
ETCD_LISTEN_PEER_URLS="http://10.0.0.1:2380"
# 广播给集群内其他成员访问的URL
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.0.0.1:2380"
# 初始及群成员列表
ETCD_INITIAL_CLUSTER="etcd1=http://10.0.0.1:2380,etcd2=http://10.0.0.2:2380,etcd3=http://10.0.0.3:2380"
# 初始集群状态，new为新建集群
ETCD_INITIAL_CLUSTER_STATE="new"
# 集群名称
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

