docker run --rm -i \
  -v $(pwd)/filebeat.yml:/usr/share/filebeat/filebeat.yml \
  docker.elastic.co/beats/filebeat:7.8.0 \
  -e -d "*" 

运行后控制终端直接输入要input的日志，然后观察debug日志 看是否不符合日志格式
