1.什么是influxdb
influxdb 是开源的时序数据库。1.x版本没有web gui页面，2.x才有
2.influx 使用cli
## 配置influxdb 连接 aws timestream
influx config create --config-name my-config \
  --host-url "https://cwallet-db-6zc7zpkjhpejf2.ap-northeast-1.timestream-influxdb.amazonaws.com:8086" \
  --org "$org" \
  --token "$token" \
  --active
## 修改task 状态配置
influx task update --id 0f21309eaa909000 --status inactive
## 查看指定task 详细信息
influx task list --json | jq '.[] | select(.id == "0f0f05153c977000")'
## 
influx query '
import "influxdata/influxdb/schema"
schema.measurements(bucket: "assets")
## influx cli 
influx v1 shell
