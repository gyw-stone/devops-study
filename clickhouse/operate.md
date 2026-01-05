## 相关操作笔记
1.热加载配置
登录集群，SYSTEM RELOAD CONFIG;

2.检查当前使用zk连接器的具体信息
SELECT name, host, port, connected_time FROM system.zookeeper_connection;
