# 1.开启动态配置,3个节点以上才可以用
reconfig=true
dynamicConfigFile=/data/zookeeper/zoo.cfg.dynamic

# 2.zkCli.sh 开启sasl想成功执行
zoo_jaas.conf 的 user_username 必须和client的username一样

# 3.观察同步数据状态
echo mntr | nc localhost 2181 | grep -E "(zk_server_state|zk_peer_state|zk_observer_master_id|zk_packets_received|^zk_approximate_data_size)"

echo srvr | nc 127.0.0.1 2181 | egrep "Zxid|Mode"

# 4.数据一致性校验
# 分别在leader 和 新增follower上观察 epoch 是否一致
cat /data/zookeeper/data/acceptedEpoch
cat /data/zookeeper/data/currentEpoch

# 分别在leader 和新增follower 观察 Node count 是否落后太多
echo "srvr" | nc 127.0.0.1 2181

# 检查leader 状态 
echo mntr | nc localhost 2181 | grep -E "zk_synced_followers|zk_avg_latency|zk_synced_observers|zk_outstanding_requests|zk_znode_count|zk_watch_count"


