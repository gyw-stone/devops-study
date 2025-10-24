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

