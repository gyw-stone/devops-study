简介：

`filebeat`是日志数据采集器，可代替`logstash`收集日志，部署起来比较方便。

一般日志量比较大，会先收集到`kafka`然后再进行消费。

架构为filebeat收集日志，推送给Kafka，然后Kafka-->logsmash-->es

一、快速安装版本

安装：

`yum -y install https://mirrors.tuna.tsinghua.edu.cn/elasticstack/8.x/yum/8.16.0/filebeat-8.16.0-x86_64.rpm` （Redhat版本）

Ubuntu 用 apt-get 下载

配置：

`vim /etc/filebeat/filebeat.yml`

```
filebeat.inputs: 
- type: log
  paths: 
    - /data/deploy_doc_process_v2_release/doc_process/swarm/x86/logs/*/*.log
  include_lines: ['ERROR', 'DEBUG', 'INFO']
  close_inactive: 5m
  backoff: 1s
  max_backoff: 1s
  multiline.pattern: '^\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}'
  multiline.negate: true
  multiline.match: after
output.kafka:
  hosts: ["172.26.24.105:9092","172.26.24.106:9092","172.26.24.107:9092"]
  topic: "wiki_log"
  partition.round_robin:
    reachable_only: true
  required_acks: 1
  compression: gzip
  max_message_bytes: 10000000
```

服务管理：

`systemctl enable filebeat`

`systemctl start filebeat`

二、容器版本

思路：启动容器，把要收集的日志以及配置文件`filebeat.yml`挂载到容器里面，然后配置文件写的日志为容器里面的路径

docker

`docker run -d --name filebeat -v /root/filebeat.yml:/usr/share/filebeat/filebeat.yml \
-v /data/redm/redmine-5.0.1/log:/usr/share/filebeat/logs/ elastic/filebeat:7.17.3`

配置文件

```
filebeat.inputs: 
- type: log
  paths: 
    #- /nas/product/confluence-deploy/data/confluence/logs/*.log 
    - /usr/share/filebeat/logs/*.log 
  include_lines: ['ERROR', 'DEBUG', 'INFO']
  close_inactive: 5m
  backoff: 1s
  max_backoff: 1s
  multiline.pattern: '^\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}'
  multiline.negate: true
  multiline.match: after
output.kafka:
  hosts: ["172.26.24.105:9092","172.26.24.106:9092","172.26.24.107:9092"]
  topic: "wiki_log"
  partition.round_robin:
    reachable_only: true
  required_acks: 1
  compression: gzip
  max_message_bytes: 10000000
```

Docker-compose.yml

```
version: "3"
services:
  filebeat:
    image: elastic/filebeat:7.17.3
    volumes:
     - /nas/product/confluence-deploy/data/confluence/logs/*.log:/usr/share/filebeat/dockerlogs/data:ro
     - /var/run/docker.sock:/var/run/docker.sock
     - /root/filebeat.yml:/usr/share/filebeat/filebeat.yml
```

`filebeat.yml`例子

```
filebeat.inputs:
- type: container
  paths:
    - /usr/share/filebeat/dockerlogs/data/*/*.log
    - /var/lib/docker/containers/3da1d32b390382b0474a6d5651629f9c6b477090056ef975789addcaf49005de/*.log
  close_timeout: 5m
  multiline.pattern: '^\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}'
  multiline.negate: true
  multiline.match: after

- type: log
  paths:
    - /usr/share/filebeat/filelogs/data/*/*log*/*.log
    - /usr/share/filebeat/filelogs/logs/*/*.log
  include_lines: ['ERROR', 'DEBUG', 'INFO']
  close_inactive: 5m
  backoff: 1s
  max_backoff: 1s
  multiline.pattern: '^\d{4}\-\d{2}\-\d{2}\s\d{2}:\d{2}:\d{2}'
  multiline.negate: true
  multiline.match: after
processors:
- add_docker_metadata:
    match_source: true
    match_source_index: 5
logging.level: info
logging.to_files: true
logging.files:
  path: /tmp/filebeat
  name: filebeat
  keepfiles: 2
  permissions: 0644

output.kafka:
  hosts: ["172.26.24.105:9092","172.26.24.106:9092","172.26.24.107:9092"]
  topic: "chengdu-im-test-logs"
  partition.round_robin:
    reachable_only: true
  required_acks: 1
  compression: gzip
  max_message_bytes: 10000000
```



