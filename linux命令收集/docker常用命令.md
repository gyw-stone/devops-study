1 显示某个容器状态

`docker inspect <container_name_or_id> --format "{{.State.Status}}"`

内存占用前十

`ps aux --sort=-%mem | head -n 11`

`top -o RES -n 15`

2 docker安装指定版本

```
# 先安装repo，再执行以下命令
yum install -y docker-ce-20.10.20 docker-ce-cli-20.10.20 containerd.io
```



