## 相关操作笔记
1.热加载配置
登录集群，SYSTEM RELOAD CONFIG;

2.检查当前使用zk连接器的具体信息
SELECT name, host, port, connected_time FROM system.zookeeper_connection;

3.迁移集群
新集群创建表
然后
INSERT INTO database_name.table_name
SELECT *
FROM remote('新集群IP:9000', 'database_name.table_name', 'user_name', 'user_password');
