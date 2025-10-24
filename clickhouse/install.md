# 现状
已有一台单节点运行，需要转成集群模式
# 安装集群
架构： 2 server+keeper 1 单独keeper，keeper组成集群，然后2个分片
rpm方式安装:
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo
sudo yum install -y clickhouse-server clickhouse-client (2台机器装)
sudo yum install -y clickhouse-keeper (独立安装机器）
## /etc/hosts 配置解析
hostname IP1
hostname Ip2

## clickhouse-keeper 核心配置
cat /etc/clickhouse-keeper/keeper_config.xml
<clickhouse>
    <logger>
        <level>trace</level>
        <log>/var/log/clickhouse-keeper/clickhouse-keeper.log</log>
        <errorlog>/var/log/clickhouse-keeper/clickhouse-keeper.err.log</errorlog>
        <size>1000M</size>
        <count>10</count>
    </logger>

    <max_connections>4096</max_connections>
    <listen_host>0.0.0.0</listen_host>  # 新增
    <keeper_server>
            <tcp_port>9181</tcp_port>
            <server_id>2</server_id> # 3个keeper只有id不一致，1，2，3...

            <log_storage_path>/data/clickhouse/keeper/coordination/logs</log_storage_path> # 修改存储数据目录
            <snapshot_storage_path>/data/clickhouse/keeper/coordination/snapshots</snapshot_storage_path> # 修改数据存储目录

            <coordination_settings>
                <operation_timeout_ms>10000</operation_timeout_ms>
                <min_session_timeout_ms>10000</min_session_timeout_ms>
                <session_timeout_ms>100000</session_timeout_ms>
                <raft_logs_level>information</raft_logs_level>
                <compress_logs>false</compress_logs>
            </coordination_settings>

            <hostname_checks_enabled>true</hostname_checks_enabled>
            <raft_configuration>
                <server>
                    <id>1</id>
                    <hostname>ch1</hostname> # 对应的hostname
                    <port>9234</port>
                </server>
                <server>
                    <id>2</id>
                    <hostname>ch2</hostname>
                    <port>9234</port>
                </server>
                <server>
                    <id>3</id>
                    <hostname>ch3</hostname>
                    <port>9234</port>
                </server>

            </raft_configuration>
    </keeper_server>

    <openSSL>
      <server>
            <verificationMode>none</verificationMode>
            <loadDefaultCAFile>true</loadDefaultCAFile>
            <cacheSessions>true</cacheSessions>
            <disableProtocols>sslv2,sslv3</disableProtocols>
            <preferServerCiphers>true</preferServerCiphers>
        </server>
    </openSSL>

</clickhouse>

sudo systemctl start clickhouse-keeper.service
sudo ssytemctl enable clickhouse-keeper.service --now

## clickhouse-server 核心配置
cat /etc/clickhouse-server/config.xml
    <storage_configuration>
        <disks>
            <local_hot>
                <path>/data/clickhouse/hot/</path>
                <keep_free_space_bytes>0</keep_free_space_bytes>
            </local_hot>
            <s3_cold>
                <type>s3</type>
                <endpoint>https://cctip-clickhouse.s3.ap-northeast-1.amazonaws.com/</endpoint>
                <use_environment_credentials>true</use_environment_credentials> ## 这里用的绑定role到ec2
            </s3_cold>
        </disks>
        <policies>
            <hot_to_cold>
                <volumes>
                    <hot>
                        <disk>local_hot</disk>
                    </hot>
                    <cold>
                        <disk>s3_cold</disk>
                    </cold>
                </volumes>
                <move_factor>0.2</move_factor>
            </hot_to_cold>
        </policies>
    </storage_configuration>
   <remote_servers>
        <my_cluster>
            <shard>
                <replica>
                    <host>ch-server1</host>
                    <port>9000</port>
                </replica>
            </shard>
            <shard>
                <replica>
                    <host>ch-server2</host>
                    <port>9000</port>
                </replica>
            </shard>
        </my_cluster>
    </remote_servers>

    <zookeeper>
        <node>
            <host>ch1</host>
            <port>9181</port>
        </node>
        <node>
            <host>ch2</host>
            <port>9181</port>
        </node>
        <node>
            <host>ch3</host>
            <port>9181</port>
        </node>
    </zookeeper>

    <macros>
        <shard>1</shard>      <!-- Set to 1 on server1, 2 on server2 -->
        <replica>replica1</replica> <!-- Set unique value per server -->
    </macros>
## clickhouse-server 密码配置
cat /etc/clickhouse-server/users.d/default-password.xml
<clickhouse>
    <users>
        <default>
            <password>CCtipclickhouse9000DB</password>
        </default>
    </users>
</clickhouse>

sudo systemctl start clickhouse-server.service
sudo systemctl enable clickhouse-server.service --now

FAQ:
注意s3绑定要权限，最好用role绑定,配合上面的配置<use_environment_credentials>true</use_environment_credentials>
## 验证keeper集群，看输出是否有leader，follower
echo 'stat' | nc 127.0.0.1 9181  # 必须启动svc，不然通信不了，集群不成功
## 验证server集群
select * from system.clusters;
---建表---
CREATE TABLE default.test_cluster ON CLUSTER default
(
    id UInt64,
    dt DateTime
)
ENGINE = ReplicatedMergeTree(
    '/clickhouse/tables/{shard}/test_cluster',
    '{replica}'
)
ORDER BY id;

---查看副本状态---
SELECT * FROM system.replicas 


## kafka engine 使用
## clickhouse 连接 kafka
CREATE TABLE cctip_db_account.kafka_cctip_user_assets ON CLUSTER default
(
    value String
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka-broker-0.kafka-broker-headless.middleware.svc.cluster.local',
    kafka_topic_list = 'cwallet.cctip-db-account.cctip-user-assets',
    kafka_group_name = 'clickhouse_assets_group_test',
    kafka_format = 'JSONAsString',
    kafka_num_consumers = 1;
## 创建对应视图表
CREATE MATERIALIZED VIEW cctip_db_account.kafka_cctip_user_assets_mv ON CLUSTER default
TO cctip_user_assets
AS
SELECT
    if(JSONExtractString(value, 'payload','op') = 'd',
       JSONExtractInt(value, 'payload','before','id'),
       JSONExtractInt(value, 'payload', 'after', 'id')) AS id,
    if(JSONExtractString(value, 'payload','op') = 'd',
       JSONExtractString(value, 'payload','before','uuid'),
       JSONExtractString(value, 'payload','after','uuid')) AS uuid,
    if(JSONExtractString(value, 'payload','op') = 'd',
       JSONExtractString(value, 'payload','before','chain_id'),
       JSONExtractString(value, 'payload','after','chain_id')) AS chain_id,
    if(JSONExtractString(value, 'payload','op') = 'd',
       JSONExtractString(value, 'payload','before','contract'),
       JSONExtractString(value, 'payload','after','contract')) AS contract,
    toDecimal256(
       coalesce(
           if(JSONExtractString(value, 'payload','op') = 'd',
              JSONExtractString(value, 'payload','before','balance'),
              JSONExtractString(value, 'payload','after','balance')),
           '0'
       ), 30
    ) AS balance,
    toDecimal256(
       coalesce(
           if(JSONExtractString(value, 'payload','op') = 'd',
              JSONExtractString(value, 'payload','before','frozen'),
              JSONExtractString(value, 'payload','after','frozen')),
           '0'
       ), 30
    ) AS frozen,
    if(JSONExtractString(value, 'payload', 'op') = 'd',
       JSONExtractInt(value, 'payload','before','version'),
       JSONExtractInt(value, 'payload','after','version')) AS version,
    toDateTime(
       if(JSONExtractString(value, 'payload', 'op') = 'd',
          JSONExtractInt(value, 'payload','before','updated'),
          JSONExtractInt(value, 'payload','after','updated')) / 1000
    ) AS updated,
    toDateTime(
       if(JSONExtractString(value, 'payload', 'op') = 'd',
          JSONExtractInt(value, 'payload','before','created'),
          JSONExtractInt(value, 'payload','after','created')) / 1000
    ) AS created,
    if(JSONExtractString(value, 'payload', 'op') = 'd',
       JSONExtractInt(value, 'payload','before','merged'),
       JSONExtractInt(value, 'payload','after','merged')) AS merged,
    if(JSONExtractString(value, 'payload', 'op') = 'd',
       JSONExtractString(value, 'payload','before','remark'),
       JSONExtractString(value, 'payload','after','remark')) AS remark,
    if(JSONExtractString(value, 'payload', 'op') = 'd',
       JSONExtractString(value, 'payload','before','ref_hash'),
       JSONExtractString(value, 'payload','after','ref_hash')) AS ref_hash,
    JSONExtractString(value, 'payload', 'op') AS op,
    if(JSONExtractString(value, 'payload', 'op') = 'd', 1, 0) AS is_delete
FROM kafka_cctip_user_assets;

## kafka触发增量快照
kafka-console-producer.sh --broker-list kafka-broker-0.kafka-broker-headless.middleware.svc.cluster.local:9092 --topic debezium-signals --property "parse.key=true" --property "key.separator=:"
# 上面命令后敲击的触发消息
cwallet:{"type":"execute-snapshot","data": {"data-collections": ["cctip-db-account.cctip-user-assets", "cctip-db-account.cctip-user-assets-flows"], "type": "incremental"}}
