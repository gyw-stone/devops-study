要监控Docker容器，Zabbix Server需要安装Docker模块。在Zabbix Server上安装Docker模块后，可以使用Zabbix Agent监控Docker容器。以下是在Zabbix Server上安装Docker模块的步骤：

1. 安装Docker

在Zabbix Server上安装Docker，可以使用以下命令：

```
sudo apt-get update
sudo apt-get install docker.io
```

2. 安装Zabbix Docker模块

使用以下命令安装Zabbix Docker模块：

```
sudo apt-get install zabbix-agent-docker
```

3. 配置Zabbix Docker模块

编辑Zabbix Agent配置文件`/etc/zabbix/zabbix_agentd.conf`，添加以下内容：

```
UserParameter=docker.containers.discovery,/usr/bin/docker-containers-discovery.sh
UserParameter=docker.container[*],/usr/bin/docker-container.sh $1 $2
```

4. 创建脚本

创建`/usr/bin/docker-containers-discovery.sh`脚本，内容如下：

```
#!/bin/bash
containers=$(sudo docker ps -q)
json="{\"data\":["
for container in $containers
do
    name=$(sudo docker inspect --format='{{.Name}}' $container | sed 's/\///g')
    json=$json"{\"{#CONTAINERNAME}\":\"$name\"},"
done
json=$(echo $json | sed 's/,$//')
json=$json"]}"
echo $json
```

创建`/usr/bin/docker-container.sh`脚本，内容如下：

```
#!/bin/bash
if [ "$1" = "status" ]; then
    status=$(sudo docker inspect --format='{{.State.Status}}' $2)
    echo $status
fi
if [ "$1" = "cpu" ]; then
    cpu=$(sudo docker stats --no-stream=true --format '{{.CPUPerc}}' $2 | sed 's/%//g')
    echo $cpu
fi
if [ "$1" = "memory" ]; then
    memory=$(sudo docker stats --no-stream=true --format '{{.MemUsage}}' $2 | sed 's/[^0-9]*//g')
    echo $memory
fi
```

5. 重启Zabbix Agent

重启Zabbix Agent，使配置生效：

```
sudo systemctl restart zabbix-agent
```

6. 添加主机

在Zabbix Server上添加主机，并在主机配置中启用Docker监控。在主机配置中，选择“添加应用程序”，然后选择“Docker”应用程序。保存配置后，Zabbix Server将开始监控Docker容器。





