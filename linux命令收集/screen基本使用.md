screen

介绍：unix/linux的终端管理，可以新开界面，并保持后台运行

<h3>安装
</h3>

```shell
# 检查是否安装
screen -v
# CentOS/RedHat/Fedora
yum -y install screen
# Ubuntu/Debian
apt-get -y install screen
```

<h3>启动
</h3>

```shell
# 随机命名启动
screen
# 指定名字启动
screen -S name
```

<h3>分离screen
</h3>

```
按下Ctrl+A，再Ctrl+D
```

<h3> 重连

```shell
# only one
screen -r
# 多个
# 先ls列出
screen -ls

There are screens on:
7880.session    (Detached)
7934.session2   (Detached)
7907.session1   (Detached)
3 Sockets in /var/run/screen/S-root.
# 再选择其中一个id or name都可以
screen -r 7880
```

<h3>中止

```shell
# screen中
ctrl+d终止
exit
# 分离状态screen -ls，再
screen -r 7880 -X quit
```

<h3>界面更多操作
`Ctrl+?`查询