## 架构
filebeat-->logstash-->es-->kibana
filebeat 是 k8s sidecar
es logstash kibana 是外部机器部署，filebeat通过内网IP 直接连接logstash
日志多可以用kafka解藕，加快查询速度加redis缓存
## rpm安装
1.所有节点安装es 9.0.3
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 9.x packages
baseurl=https://artifacts.elastic.co/packages/9.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
EOF

dnf install --enablerepo=elasticsearch elasticsearch

主节点修改配置/etc/elasticsearch/elasticsearch.yaml
cluster.name: bankpayos-es
node.name: master-1

path.data: /data/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
discovery.seed_hosts: ["172.31.13.249:9300"]
cluster.initial_master_nodes: ["master-1"]

http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization
xpack.security.enabled: true

xpack.security.enrollment.enabled: true

xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12

xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12

http.host: 0.0.0.0

transport.host: 0.0.0.0

主节点修改配置/etc/elasticsearch/jvm.options
-Xms16g
-Xmx16g
-XX:+UseG1GC
-Djava.io.tmpdir=${ES_TMPDIR}
20-:--add-modules=jdk.incubator.vector
23:-XX:CompileCommand=dontinline,java/lang/invoke/MethodHandle.setAsTypeCache
23:-XX:CompileCommand=dontinline,java/lang/invoke/MethodHandle.asTypeUncached
-Dorg.apache.lucene.store.defaultReadAdvice=normal
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-XX:HeapDumpPath=/var/lib/elasticsearch
-XX:ErrorFile=/var/log/elasticsearch/hs_err_pid%p.log
-Xlog:gc*,gc+age=trace,safepoint:file=/var/log/elasticsearch/gc.log:utctime,level,pid,tags:filecount=32,filesize=64m

主节点启动：
systemctl start elasticsearch.service
systemctl enable elasticsearch.service --now

# 重置密码
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic 

丛节点加入集群：
主节点生成token: 
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
丛节点配置：
/usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token <token-here>
然后修改下node_name之类,启动服务

## 验证集群状态
curl -k -u elastic:xeE0caLCvJ2n0vmoK+4d https://localhost:9200/_cat/nodes?v

2.安装kibana
dnf install --enablerepo=elasticsearch kibana
es 主节点生成token
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
# 绑定es
sudo -u kibana /data/kibana/kibana-9.0.3/bin/kibana-setup --enrollment-token ""
##  检查elastic/kibana 是否正常
curl -X GET -k -u elastic:xeE0caLCvJ2n0vmoK+4d \
"https://localhost:9200/_security/service/elastic/kibana"
## 生成kibana-token
curl -X POST -k -u elastic:xeE0caLCvJ2n0vmoK+4d \
"https://localhost:9200/_security/service/elastic/kibana/credential/token/kibana-token" \
-H "Content-Type: application/json" -d'
{
  "name": "kibana-token"
}'

3.安装logstash
dnf install --enablerepo=elasticsearch logstash

## 创建logstash读取角色
curl -k -X POST -u elastic:xeE0caLCvJ2n0vmoK+4d "https://localhost:9200/_security/role/logstash_k8s_writer" -H "Content-Type: application/json" -d '{
  "cluster": ["monitor", "manage_index_templates"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["create_index", "write", "delete", "index", "manage"]
    }
  ]
}'
## 创建logstash_k8s_writer 用户
curl -k -X POST -u elastic:xeE0caLCvJ2n0vmoK+4d \
"https://localhost:9200/_security/user/logstash_k8s_writer" \
-H "Content-Type: application/json" \
-d '{
  "password": "hash@23eormwejw",
  "roles": ["logstash_k8s_writer"],
  "full_name": "K8s Logs Ingestor"
}'

## logstash 配置文件验证
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t

## logstash 9.0.3 坑
1. role绑定跟es
2. logstash_k8s_writer 用户需要有写入权限，index一定要为*,不然写不进去

# cat es-output.conf_0725bak
input {
  beats {
    port => 5044
    host => "0.0.0.0"
  }
}

filter {
  if [app-namespace] == "" {
    mutate {
      add_field => { "[@metadata][namespace]" => "default" }
    }
  } else {
    mutate {
      add_field => { "[@metadata][namespace]" => "%{app-namespace}" }
    }
  }
}

output {
  elasticsearch {
    hosts => [
      "https://172.31.13.249:9200",
      "https://172.31.79.34:9200"
    ]
    data_stream => false
    index => "%{[@metadata][namespace]}-%{+YYYY.MM.dd}"
    user => "logstash_k8s_writer"
    password => "hash@23eormwejw"
    ssl_enabled => true
    ssl_certificate_authorities => "/etc/logstash/certs/http_ca.crt"
    retry_on_conflict => 3
    action => "create"  # 避免文档冲突
  }
}

4.filebeat siedecar
apiVersion: v1
kind: ConfigMap
metadata:
  name: filebeat-config
  namespace: logger
data:
  filebeat.yml: |
    filebeat.inputs:
    - type: filestream
      id: my-filestream-id
      paths:
        - /app/log/service.log
      tail_files: true
      ignore_older: 24h
      harvester_limit: 1000
      fields:
        app-namespace: '${appNamespace}'
        app-name: '${appName}'
        app-ip: '${appIp}'
      fields_under_root: true  
      #parsers:
      #- multiline:
      #    type: pattern
      #    pattern: '^\d{4}-\d{2}-\d{2}' 
      #    negate: true
      #    match: after

    processors:
    - decode_json_fields:
        fields: ["message"]
        target: ""
        overwrite_keys: true
     #   add_error_key: true
    - drop_fields:
        fields: ["agent.type", "agent.version","agent.hostname","agent.ephemeral_id","agent.id","log.file.path","input.type","ecs.version","agent.name","msg","time","caller","module","service.id","service.name","service.version","span.id","ts"]
        ignore_missing: true

    output.logstash:
      hosts: ["172.31.13.249:5044"]
      bulk_max_size: 100
      ssl.enabled: false
      worker: 2  # 提升并发
      codec.json:
        pretty: false
      keep_alive: 30s

    # 新增：资源优化配置
    queue:
      mem:
        events: 1024
        flush.min_events: 128
    logging.level: info
---
## filebeat 配置官方参考文档：https://www.elastic.co/docs/reference/beats/filebeat/filebeat-input-filestream#filestream-recursive-glob
