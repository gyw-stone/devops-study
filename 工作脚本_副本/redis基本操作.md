```shell
# 连接
~ redis-cli -h 127.0.0.1 -p 6379
# 授权
~ 127.0.0.1:6379>auth xxx
# 选择DB(0-15)
~ 127.0.0.1:6379>select 0
# String类型设置
~ 127.0.0.1:6379>set RDS_TEST_KEY test
# String类型获取
~ 127.0.0.1:6379>get RDS_TEST_KEY
# 查看key过期时间
~ 127.0.0.1:6379>ttl RDS_TEST_KEY
# 设置key 10s过期
~ 127.0.0.1:6379>expire RDS_TEST_KEY
# list类型左入队
~ 127.0.0.1:6379>lpush RDS_TEST_KEY_list item1
# list类型右出队
~ 127.0.0.1:6379>rpop RDS_TEST_KEY_list
# 查看redis中的信息
~ 127.0.0.1:6379>info
# 清除db中的数据
~ 127.0.0.1:6379>flushdb
```

