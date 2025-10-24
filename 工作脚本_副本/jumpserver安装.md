1.升级内核到大于4.0

```
wget http://download.datagrand.com/download/kernel/centos7/5.4-lt/kernel-5.4.278.tgz 
tar xzf kernel-5.4.278.tgz 
cd kernel
1. 卸载老内核
  rpm -e kernel-headers --nodeps
  rpm -e kernel-devel --nodeps
  rpm -e kernel-tools-libs --nodeps
  rpm -e kernel --nodeps
  rpm -e kernel-tools --nodeps
2. 安装新内核
   yum localinstall ./*.rpm -y
3. 查看内核启动顺序、设置内核启动
   awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
   grub2-set-default 0
4. 生成grub 配置文件
   grub2-mkconfig -o /boot/grub2/grub.cfg
5. reboot
6. uname -a
```

2.安装MariaDb

```
# vi /etc/yum.repos.d/MariaDB.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/11.5.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1

# yum update
# yum install MariaDB-server MariaDB-client -y
systemctl start mariadb
systemctl enable mariadb
systemctl status mariadb

mysql -u root -p

create database jumpserver default charset 'utf8';
show create database jumpserver;
```

3.安装redis

```
wget https://download.redis.io/releases/redis-7.2.5.tar.gz
tar xzf redis-7.2.5.tar.gz
cd redis-7.2.5/
yum -y install gcc gcc-c++ kernel-devel
make MALLOC=libc
cd src
./redis-server &
```

4.安装jumpserver

```
curl -sSL https://resource.fit2cloud.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
```

```
1. 可以使用如下命令启动, 然后访问
cd /opt/jumpserver-installer-v3.10.11
./jmsctl.sh start

2. 其它一些管理命令
./jmsctl.sh stop
./jmsctl.sh restart
./jmsctl.sh backup
./jmsctl.sh upgrade
更多还有一些命令, 你可以 ./jmsctl.sh --help 来了解

3. Web 访问
http://172.26.25.109:80
默认用户: admin  默认密码: admin

4. SSH/SFTP 访问
ssh -p2222 admin@172.26.25.109
sftp -P2222 admin@172.26.25.109
```
