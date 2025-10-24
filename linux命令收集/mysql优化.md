```
给大家分享个mysql 优化参数：
##slow log
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=0.8
##
max_connections=2000
max_connect_errors=10
max_user_connections=1980
back_log = 600
character-set-server=utf8
default_authentication_plugin=mysql_native_password
default-storage-engine=INNODB
innodb_buffer_pool_size=24G
innodb_io_capacity=800
innodb_thread_concurrency=8
table_open_cache=1024
thread_cache_size=512
#innodb_flush_log_at_trx_commit=1
#sync_binlog=1
innodb_max_dirty_pages_pct=30
#innodb_io_capacity=200
#innodb_data_file_path=ibdata1:1024M:autoextend
binlog_format=row
interactive_timeout=500
wait_timeout=500
innodb_log_file_size=256M
innodb_log_buffer_size=16M
innodb_flush_log_at_trx_commit=2
sync_binlog=2
innodb_file_per_table=1
```



