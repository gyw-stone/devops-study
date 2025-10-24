## 安装
参考链接: https://rocketmq.apache.org/zh/docs/quickStart/01quickstart

## 架构
生产者-->消息存储-->消费者
消息存储: 
  Topic: 定义数据分类隔离，数据身份和权限
  Message: 消息存储和传输的实际容器，最小存储单元，保证存储顺序性和流式操作语义
  Queue Message: 最小数据传输单元，消息产生后不可变且具有持久化性
消息消费: 
  ConsumerGroup: 承载消费行为一致的消费者的负载均衡分组
  Consumer: 接收并处理消息的运行实体
  Subscription: 消费者获取消息、处理消息的规则和状态配置

## 
