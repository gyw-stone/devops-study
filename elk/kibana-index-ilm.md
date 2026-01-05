## ilm 解决 logstash 给的index为xxx-%{YYYYMMDD}等方式,采用策略直接delete，不用hot的rollover
1.创建ilm，关闭hot，开启delete
PUT _ilm/policy/15days_policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {}
      },
      "delete": {
        "min_age": "15d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}

2.创建index_template 绑定 ilm_policy 到 index_template 的 index setting上
PUT _template/15days_template_test_nginx
{
  "order": 0,
  "index_patterns": [
    "test_nginx_logger_record-*"
  ],
  "settings": {
    "index": {
      "lifecycle": {
        "name": "15days_policy"
      },
      "refresh_interval": "30s",
      "number_of_shards": "1",
      "number_of_replicas": "1",
      "translog": {
        "sync_interval": "10s",
        "durability": "async"
      },
      "unassigned": {
        "node_left": {
          "delayed_timeout": "30m"
        }
      }
    }
  },
  "mappings": {
    "_doc": {
      "_source": {
        "enabled": true
      },
      "properties": {}
    }
  },
  "aliases": {}
}

3.验证是否生效
# 查看索引是否挂上ilm, index 下 有一个lifestyle的ilm策略
GET test_nginx_logger_record-2025.12.12/_settings?filter_path=*.settings.index.lifecycle
# 看ilm状态,会有一个complete
GET test_nginx_logger_record-2025.12.12/_ilm/explain

