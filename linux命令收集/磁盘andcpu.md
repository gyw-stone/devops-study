CPU

**1.查看所有逻辑CPU的个数(几核)**

`cat /proc/cpuinfo | grep "processor" | wc -l`
输出结果：
32
表示Linux服务器一共有32个逻辑CPU。

**2. 查看cpu详细信息**

`cat /proc/cpuinfo`



内存

**1.查看占用内存排名前十**

`ps aux | sort -k4,4nr | head -n 10`



`mysql: Datagrand@123`

mysql-client-8.0                                install
mysql-client-core-8.0                           install
mysql-common                                    install
mysql-server                                    install
mysql-server-8.0                                install
mysql-server-core-8.0                           install

`grant all on *.* to root@'%' identified by '数据库密码';`



```
systeminfo | find "Original Install Date"
# 操作系统安装日期

```

```
# grafana。查询慢优化的思路
highmax 函数 or alias别名 reduce the size of the returned series name
# 使用public dashboards，read-only，多次访问建议使用
# https://grafana.com/docs/grafana/latest/dashboards/dashboard-public/

```

```
# grafana模版
集群资源监控：3119
• 资源状态监控 ：6417
• Node监控 ：9276
```

