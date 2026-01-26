
# 情况 cpu 高 load高
top 找cpu占用最多的进程pid, top -HP pid

# 情况cpu 低 load高
查看io wait高不高，iostat -x 1 
sar -u 1 5
pidstat -u 1 5
vmstat 1 5
mpstat -P ALL 1 3

参考链接: https://help.aliyun.com/zh/ecs/support/query-and-analysis-of-system-loads-on-linux-instances
