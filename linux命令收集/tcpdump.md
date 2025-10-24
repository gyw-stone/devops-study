```
# -i 接制定网口，host为指定IP地址
tcpdump -i ens33 host 10.193.12.111
# 指定通过网口ens33，并且主机10.193.12.12和10.193.12.111或10.193.12.112之间的通信
tcpdump -i ens33 -n host 10.193.12.12 and 10.193.12.111or10.193.12.112
# 指定通过网口ens33, 并且主机10.193.12.12 和非主机10.193.17.4之间的通信
tcpdump -i ens33 -n host 10.193.12.12 and ! 10.193.17.4
# 指定通过网口ens33, 并且由主机10.193.12.12发送的所有数据
tcpdump -i ens33 -n src 10.193.12.12
# 指定通过网口ens33, 并且由主机10.193.12.12接收的所有数据
tcpdump -i ens33 -n dst 10.193.12.12
# 指定通过网口ens33, 并且由主机10.193.12.12接收的连续5个数据包,+‘-q’表示精简显示
tcpdump -i ens33 -n dst 10.193.12.12 -c 5
# 按照协议icmp抓包
tcpdump -i ens33 -n icmp
# 指定网卡ens33，端口号为55555并且ip地址为10.193.12.12的连续10个数据包
tcpdump -i ens33 -n tcp port 55555 and host 10.193.12.12 -c 10
# 抓包并保存package.cap文件，可导出后再导入wireshark进行包分析
tcpdump -i ens33 -n  port 55555 and host 10.193.12.12 -c 10 -w package.cap
```

