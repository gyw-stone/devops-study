## 1.安装java jdk
rpm -i https://download.oracle.com/java/25/latest/jdk-25_linux-x64_bin.rpm
java --version

## 2.安装zk 3.9.1 并解压
wget https://archive.apache.org/dist/zookeeper/zookeeper-3.9.1/apache-zookeeper-3.9.1-bin.tar.gz
tar -xf apache-zookeeper-3.9.1-bin.tar.gz
mv apache-zookeeper-3.9.1-bin /opt/zookeeper-3.9.1/

## 3.修改配置
mkdir -p /data/zookeeper/data
cd /opt/zookeeper-3.9.1/conf

# vim zoo.cfg

tickTime=2000
initLimit=10
syncLimit=5
dataDir=/bitnami/zookeeper/data
clientPort=2181
maxClientCnxns=60
autopurge.snapRetainCount=3
autopurge.purgeInterval=24

## Metrics Providers
#
# https://prometheus.io Metrics Exporter
#metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
#metricsProvider.httpHost=0.0.0.0
#metricsProvider.httpPort=7000
#metricsProvider.exportJvmInfo=true
preAllocSize=65536
snapCount=100000
maxCnxns=0
reconfigEnabled=false
quorumListenOnAllIPs=false
4lw.commands.whitelist=srvr, mntr, ruok
maxSessionTimeout=40000
admin.serverPort=8080
admin.enableServer=true
server.1=zookeeper-0.zookeeper-headless.middleware.svc.cluster.local:2888:3888;2181
server.2=zookeeper-1.zookeeper-headless.middleware.svc.cluster.local:2888:3888;2181
server.3=zookeeper-2.zookeeper-headless.middleware.svc.cluster.local:2888:3888;2181
server.4=ip:2888:3888:observer;2181
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
requireClientAuthScheme=sasl

## 4.用户密码写入jaas.conf,Server的user_x 的user对应Client的user,pass
# vim zoo_jaas.conf
Client {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    username="username"
    password="passwd";
};
Server {
    org.apache.zookeeper.server.auth.DigestLoginModule required
    user_username="passwd";
};

## 5.修改启用堆栈大小
vi /opt/zookeeper-3.9.1/conf/java.env
export JVMFLAGS=" -Xmx1536m -Xms1536m -Djava.security.auth.login.config=/opt/zookeeper-3.9.1/conf/zoo_jaas.conf -Dzookeeper.electionPortBindRetry=0"

## 6.创建专用用户
groupadd -r zookeeper
useradd -r -M -g zookeeper -s /bin/false -d /opt/zookeeper-3.9.1 zookeeper
chown -R zookeeper:zookeeper /opt/zookeeper-3.9.1
chown -R zookeeper:zookeeper /data/zookeeper

## 7.创建systemd 管理文件
# 创建 /etc/systemd/system/zookeeper.service
[Unit]
Description=Apache ZooKeeper
After=network.target

[Service]
Type=forking
User=zookeeper
Group=zookeeper
ExecStart=/opt/zookeeper-3.9.1/bin/zkServer.sh start
ExecStop=/opt/zookeeper-3.9.1/bin/zkServer.sh stop
ExecReload=/opt/zookeeper-3.9.1/bin/zkServer.sh restart
Restart=on-abnormal

[Install]
WantedBy=multi-user.target

## 8.验证zk状态
## 查看leader
curl http://localhost:8080/commands/leader
## 查看状态
curl http://localhost:8080/commands/stat
