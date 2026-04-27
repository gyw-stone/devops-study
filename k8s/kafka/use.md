## 列出集群列表
kafka-broker-api-versions.sh --bootstrap-server localhost:9092

## 查看配置
kafka-configs.sh \
  --bootstrap-server kafka-broker-1.kafka-broker-headless.middleware.svc.cluster.local:9092 \
  --entity-type brokers \
  --all \
  --describe

## 查看topic
kafka-topics.sh --bootstrap-server kafka-broker-1.kafka-broker-headless.middleware.svc.cluster.local:9092 --list

## 删除topic
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic test-auto-create

## 查看是否topic消息生效
kafka-console-consumer.sh \
  --bootstrap-server kafka-broker-1.kafka-broker-headless.middleware.svc.cluster.local:9092 \
  --topic cwallet.cctip-db-account.cctip-user-assets \
  --from-beginning \
  --max-messages 1

## 描述topic
kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic detrade-v3

## 创建topic
kafka-topics.sh --bootstrap-server localhost:9092 \
  --create \
  --topic schema-changes.detrade-v2-db \
  --partitions 1 \


### 扩展副本到每个node
## 生成一个分配的json文件,类似
bin/kafka-reassign-partitions.sh --bootstrap-server localhost:9092 --topics-to-move-json-file /tmp/topics.json --broker-list "1,2,3" --generate

# cat /tmp/topics.json 
{
  "version": 1,
  "partitions": [
    {
      "topic": "quickstart-events",
      "partition": 0,
      "replicas": [1, 2, 3]
    }
  ]
}
## 修改topic 然后执行这个
bin/kafka-reassign-partitions.sh --bootstrap-server localhost:9092 --reassignment-json-file /tmp/topics.json --execute

10.修改topic分区
bin/kafka-topics.sh \
 --bootstrap-server localhost:9092 \
 --alter \
 --topic stats.cctip-db-stats.cctip-user-asset-statistic-usdt \
 --partitions 6

11.查看消费者的状态
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group clickhouse_stats_cctip_user_asset_statistic_usdt

12.修改topic过期时间
bin/kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name stats.cctip-db-stats.cctip-user-asset-statistic-usdt \
  --alter \
  --add-config retention.ms=36000000

13.删除topic过期时间配置，恢复默认值
kafka-configs.sh --bootstrap-server <Broker地址> \
--entity-type topics \
--entity-name <Topic名称> \
--alter \
--delete-config retention.ms

14.指定偏移量消息查看
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
--topic stats.cctip-db-stats.cctip-user-asset-statistic-usdt \
--partition 2 \
--offset 915624911 \
--max-messages 2

15.修改topic 过期的最大存储大小，单partition的最大大小，多分区就是多个最大大小
bin/kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name stats.cctip-db-stats.cctip-user-asset-statistic-usdt \
  --alter \
  --add-config retention.bytes=$((30*1024*1024*1024))
