## 安装
kubectl apply -f deployment.yaml
## 查看所有注册器
curl -s http://localhost:8083/connectors 
## 删除
curl -X DELETE http://localhost:8083/connectors/cwallet-db-connector
## 暂停
curl -X PUT http://localhost:8083/connectors/cwallet-db-connector/pause
## 暂停恢复
curl -X PUT http://localhost:8083/connectors/<connector-name>/resume
# 建立连接
curl -X POST -H 'accept:application/json' -H 'content-type:application/json' http://127.0.0.1:8083/connectors/ --data @/kafka/connectors/mysql-connector.json
# 上面是容器内部，下面是master执行
kubectl exec -it deploy/debezium-connect -n debezium -- \
curl -X POST -H 'Content-Type: application/json' -H 'accept:application/json' \
--data @/kafka/connectors/mysql-connector.json \
http://localhost:8083/connectors
# 查看状态
curl -s http://localhost:8083/connectors/cwallet-db-connector/status
# kakfa增量调用
kafka-console-producer.sh --bootstrap-server localhost:9092 --topic debezium-signals --property "parse.key=true" --property "key.separator=:"
cwallet:{"type":"execute-snapshot","data": {"data-collections": ["cctip-db-account.cctip-user-assets", "cctip-db-account.cctip-user-assets-flows"], "type": "incremental"}}
# 更新或新建
curl -X PUT \
  -H "Content-Type: application/json" \
  http://localhost:8083/connectors/cwallet-db-connector/config \
  -d '{
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",  
    "database.hostname": "cctip-database.cwb4dfaq38cg.ap-northeast-1.rds.amazonaws.com",  
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "'"$MYSQL_PASSWORD"'",
    "database.server.id": "184054",  
    "database.ssl.mode": "disabled",
    "connect.timeout.ms": "60000",
    "topic.prefix": "cwallet",  
    "database.include.list": "cctip-db-account",  
    "schema.history.internal.kafka.bootstrap.servers": "kafka-broker-0.kafka-broker-headless.middleware.svc.cluster.local:9092,kafka-broker-1.kafka-broker-headless.middleware.svc.cluster.local:9092,kafka-broker-2.kafka-broker-headless.middleware.svc.cluster.local:9092",  
    "schema.history.internal.kafka.topic": "schema-changes.cwallet",
    "decimal.handling.mode": "string",
    "signal.kafka.topic": "debezium-signals",
    "signal.kafka.bootstrap.servers": "kafka-broker-0.kafka-broker-headless.middleware.svc.cluster.local:9092,kafka-broker-1.kafka-broker-headless.middleware.svc.cluster.local:9092,kafka-broker-2.kafka-broker-headless.middleware.svc.cluster.local:9092",
    "incremental.snapshot.chunk.size": "1024",
    "snapshot.mode": "no_data",
    "signal.enabled.channels": "source,kafka",
    "table.include.list": "cctip-db-account.cctip-user-assets,cctip-db-account.cctip-user-assets-flows",
    "signal.data.collection": "cctip-db-account.debezium_signals",
    "snapshot.locking.mode": "none",
    "errors.tolerance": "all",
    "errors.log.enable": "true",
    "errors.deadletterqueue.topic.name": "dlq.cwallet",
    "errors.deadletterqueue.context.headers.enable": "true",
    "producer.override.max.block.ms": "60000",
    "producer.override.delivery.timeout.ms": "300000",
    "producer.override.request.timeout.ms": "60000",
    "producer.override.retries": "10",
    "producer.override.retry.backoff.ms": "5000",
    "producer.override.acks": "1",
    "incremental.snapshot.watermarking.strategy": "insert_delete",
    "incremental.snapshot.chunk.size": "2048",
    "event.processing.failure.handling.mode":"warn",
    "snapshot.max.threads": "2",
    "heartbeat.interval.ms": "10000"
}'

## 优化配置
"schema.history.internal.kafka.recovery.attempts": "100",
"schema.history.internal.kafka.recovery.poll.interval.ms": "5000",

## 重置offsets 操作
curl -X PUT http://localhost:8083/connectors/cwallet-db-connector/stop
curl -X DELETE -H "Content-Type: application/json" \
  "http://localhost:8083/connectors/cwallet-db-connector/offsets"
## 报错binlog问题处理方案
1.调整binlog日志保持时间
2.停止connector
3.重置offsets
4.恢复connector


## 增量快照手动触发坑
1.用户必须要有写入信令表的权限
2.增量信息触发一次就会全量复制一次，所以执行一次信号就行了


## 迁移debezium
1.同步相关的topic，connect_xxx,schema.xxx
2.新connectors 使用schema_only 模式恢复，需要有以下两行
 "schema.history.internal.kafka.recovery.mode": "recovery",
 “snapshot.mode": "schema_only",


## 走json文件创建连接器
curl -X POST \ -H 'Content-Type: application/json' \ --data-binary @cwallet-detrade-db.json \ http://localhost:8083/connectors/cwallet-detrade-db-connector/config

## FAQ 
报错先看用户是否有权限
1.schema history isn't known
## 检测表结构topic里面是否有对应的表 
kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic schema-changes.activity-v2 \
  --from-beginning

2.debezium 出发增量成功后，clickhouse 只有最新数据
 首先检查日志，看是否有incremental xxx 的日志，如果有说明生产没问题，去看消费端 clickhouse mv表是否允许read 的操作
