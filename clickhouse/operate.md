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

4.查看系统磁盘占用
SELECT
    hostName(),
    database,
    table,
    sum(rows) AS rows,
    formatReadableSize(sum(bytes_on_disk)) AS total_bytes_on_disk,
    formatReadableSize(sum(data_compressed_bytes)) AS total_data_compressed_bytes,
    formatReadableSize(sum(data_uncompressed_bytes)) AS total_data_uncompressed_bytes,
    round(sum(data_compressed_bytes) / sum(data_uncompressed_bytes), 3) AS compression_ratio
FROM system.parts
WHERE database = 'system'
GROUP BY
    hostName(),
    database,
    table
ORDER BY sum(bytes_on_disk) DESC FORMAT Vertical

5.手动触发TTL
ALTER TABLE system.trace_log MATERIALIZE TTL;

6.直接清理分区过期数据
# 查看分区
SELECT partition, count() AS parts, formatReadableSize(sum(bytes_on_disk)) AS size
FROM system.parts
WHERE database = 'system' AND `table` IN ('text_log_0', 'trace_log_0') AND active
GROUP BY partition
ORDER BY partition ASC;

# 删除过期分区
ALTER TABLE system.text_log_0 DROP PARTITION '202506';  -- 替换为实际过期分区名

7.查看消费者状态
SELECT
    database,
    `table`,
    consumer_id,
    exceptions.text,
    exceptions.time
FROM system.kafka_consumers
FORMAT Vertical

8.查看系统表是否有报错或者积压
SELECT * FROM system.errors WHERE last_error_time > now() - interval 5 minute;
SELECT * FROM system.kafka_consumers where database='';

9.修改kafka表的engine配置，需要drop并新建
DETACH TABLE cctip_db_stats.t_cctip_user_asset_statistic_usdt_kafka on cluster default;
ATTACH TABLE cctip_db_stats.t_cctip_user_asset_statistic_usdt_kafka on cluster default;
Drop table cctip_db_stats.t_cctip_user_asset_statistic_usdt_kafka on cluster default;

10.查看目标表的总记录数和当天的去重数
SELECT
    count() AS total,
    uniqExact(user_id, current_date) AS uniq_cnt
FROM cctip_db_stats.cctip_user_asset_statistic_usdt;

11.备份相关
## 查看备份磁盘配置
SELECT name, path FROM system.disks WHERE name = 'backups'

# 备份
BACKUP DATABASE default TO Disk('backups', 'default_backup.zip');

# 恢复
RESTORE DATABASE default
FROM Disk('backups', 'default_backup.zip')
SETTINGS storage_policy='hot_to_cold';
select storage_policy,name,engine,engine_full from system.tables where database='default' and name='t_fee_bills';

12.查询正在执行的查询及其 CPU 使用率，按照用户 CPU 使用率倒序排列
SELECT
    query_id,
    query,
    elapsed,
    ProfileEvents['UserTimeMicroseconds'] AS userCPU,
    ProfileEvents['SystemTimeMicroseconds'] AS systemCPU
FROM system.processes
ORDER BY userCPU DESC;
