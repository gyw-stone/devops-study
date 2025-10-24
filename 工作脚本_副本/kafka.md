```
# 列出当前所有的topic

# 检查topic是否有最新消息进来
bin/kafka-console-consumer.sh --bootstrap-server 172.26.24.105:9092 --topic ali-im-demo-logs --from-beginning  --max-messages 1
# 查看哪些被消费
bin/kafka-consumer-groups.sh --bootstrap-server 172.26.24.105:9092 --describe --group test-consumer-group
```

```
## logstash
input{
  kafka{
    bootstrap_servers => "172.26.24.105:9092,172.26.24.106:9092,172.26.24.107:9092" # kafka地址
    group_id => "test-consumer-group" #默认为“logstash”
    topics => "dp_rabbitmq_log" # 修改处
    codec => json
    type => "input-dp_rabbitmq_log" # 修改处
    auto_offset_reset => "latest"
  }
}
output {
  if [type] == "input-dp_rabbitmq_log" { # 修改处
    elasticsearch {
      hosts => ["172.26.24.160:9288","172.26.24.161:9288","172.26.24.162:9288"]
      index => "dp_rabbitmq-%{+yyyy.MM.dd}" # 修改处
      user => "elastic"
      password=>"datagrand@123"
    }  
  }       
}  
```





