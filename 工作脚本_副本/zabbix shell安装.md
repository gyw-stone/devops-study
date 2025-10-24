```shell
#!/bin/bash
#input_IP=$1
#input_IP=10.100.13.133 
input_IP=192.168.185.21
hostIP=`hostname -I | awk '{print $1}'`
ZABBIX_AGENT_CONF="/etc/zabbix/zabbix_agentd.conf"
ZABBIX_AGENT_CONF_dkpg="/etc/zabbix/zabbix_agentd.conf.dpkg-new"
# centos7
Install() {
	sed -i "s/^Hostname=.*/Hostname=$hostIP/g" /etc/zabbix/zabbix_agent2.conf
	sed -i "s/^Server=.*/Server=$input_IP/g" /etc/zabbix/zabbix_agent2.conf
	sed -i "s/^ServerActive=.*/ServerActive=$input_IP/g" 	/etc/zabbix/zabbix_agent2.conf
	systemctl enable zabbix-agent2.service
	systemctl start zabbix-agent2.service
	systemctl status zabbix-agent2.service
}
# ubuntu
Install1() {
	sed -i "s/^Hostname=.*/Hostname=$hostIP/g"
	/etc/zabbix/zabbix_agentd.conf
	sed -i "s/^Server=.*/Server=$input_IP/g" /etc/zabbix/zabbix_agentd.conf
	sed -i "s/^ServerActive=.*/ServerActive=$input_IP/g"	/etc/zabbix/zabbix_agentd.conf
	systemctl enable zabbix-agent.service
	systemctl start zabbix-agent.service
	systemctl status zabbix-agent.service
}
# ubuntu
Modify_config() {
if [ -f "$ZABBIX_AGENT_CONF" ]; then
  Install1
elif [ -f "$ZABBIX_AGENT_CONF_dkpg" ]; then
  mv $ZABBIX_AGENT_CONF_dkpg $ZABBIX_AGENT_CONF
  Modify_config
fi
}
# 判断当前操作系统类型
if [ "$(uname -s)" = "Linux" ]; then
    if [ -f "/etc/lsb-release" ]; then
        # Ubuntu
        UBUNTU_VERSION=$(lsb_release -rs)
    
    		if [ "$UBUNTU_VERSION" = "18.04" ]; then
        	wget -O /tmp/zabbix-agent.deb http://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix/zabbix-agent_6.4.3-1%2Bubuntu18.04_amd64.deb
        	dpkg -i /tmp/zabbix-agent.deb 
        	Modify_config
    		elif [ "$UBUNTU_VERSION" = "20.04" ]; then
        	wget -O /tmp/zabbix-agent.deb http://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix/zabbix-agent_6.4.3-1%2Bubuntu20.04_amd64.deb
        	dpkg -i /tmp/zabbix-agent.deb 
        	Modify_config
        
    else
        echo "Unsupported Ubuntu version: $UBUNTU_VERSION"
        exit 1
    fi
				dpkg -i /tmp/zabbix-agent.deb 
        Modify_config
    elif [ -f "/etc/redhat-release" ]; then
        # CentOS7
        rpm -qa | grep wget > /dev/null || yum install wget -y
        wget -O /tmp/pcre2.rpm http://mirror.centos.org/centos/7/os/x86_64/Packages/pcre2-10.23-2.el7.x86_64.rpm
				rpm -ivh /tmp/pcre2.rpm 
        wget -O /tmp/zabbix_agent2.rpm http://repo.zabbix.com/zabbix/6.4/rhel/7/x86_64/zabbix-agent2-6.4.3-release1.el7.x86_64.rpm
        rpm -ivh /tmp/zabbix_agent2.rpm
        Install
    else
        echo "Unsupported Linux distribution"
        exit 1
    fi
else
    echo "Unsupported operating system"
    exit 1
fi
[ -e /tmp/zabbix_agent2.rpm ] && rm /tmp/zabbix_agent2.rpm
[ -e /tmp/zabbix-agent.deb ] && rm /tmp/zabbix-agent.deb
```

```
# 离线安装
# 依赖：gcc make pcre-devels
#!/bin/bash
wget https://cdn.zabbix.com/zabbix/sources/stable/7.0/zabbix-7.0.2.tar.gz
tar -zxf zabbix-7.0.2.tar.gz
cd zabbix-7.0.2.tar.gz
./configure --enable-agent --disable-dependency-tracking
make install 
mkdir /etc/zabbix
cp /usr/local/etc/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
input_IP=192.168.46.159
hostIP=`hostname -I | awk '{print $1}'`
sed -i "s/^Hostname=.*/Hostname=$hostIP/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Server=.*/Server=$input_IP/g" /etc/zabbix/zabbix_agentd.conf

cat >/lib/systemd/system/zabbix-agent.service <<EOF
[Unit]
Description=Zabbix Agent
After=syslog.target
After=network.target
 
[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_agentd.conf"
EnvironmentFile=-/etc/sysconfig/zabbix-agent
Type=forking
KillMode=control-group
ExecStart=/usr/local/sbin/zabbix_agentd -c $CONFFILE
ExecStop=/bin/kill -SIGTERM $MAINPID
User=daemon
Group=daemon
 
[Install]
WantedBy=multi-user.target
EOF
systemctl start zabbix-agent
```

```
ansible -i chengdu_server_list all -m shell -a "docker images|grep ocr_business_layer| grep release_ci_20211203_6a95004"
```

```
下载地址：https://cdn.zabbix.com/zabbix/sources/stable/7.0/zabbix-7.0.5.tar.gz
---
- hosts: all
  become: true
  tasks:

    - name: 创建zabbix目录
      file:
        path: /root/zabbix/zabbix-7.0.2
        state: directory
        mode: '0755'

    - name: 复制 Zabbix 二进制文件
      copy:
        src: /root/zabbix/zabbix-7.0.2/
        dest: /root/zabbix/zabbix-7.0.2/
        owner: root
        group: root
        mode: '0755'

    - name: 编译配置并安装 Zabbix agent
      command: "./configure --enable-agent --disable-dependency-tracking"
      args:
        chdir: /root/zabbix/zabbix-7.0.2
      register: configure_result

    - name: 执行 make install
      command: "make install"
      args:
        chdir: /root/zabbix/zabbix-7.0.2
      when: configure_result is changed

    - name: 创建 /etc/zabbix 目录
      file:
        path: /etc/zabbix
        state: directory
        mode: '0755'

    - name: 复制 zabbix-agent 配置文件
      copy:
        src: /etc/zabbix/zabbix-agent.conf
        dest: /etc/zabbix/zabbix-agent.conf
        owner: root
        group: root
        mode: '0644'

    - name: 设置主机名为当前 IP
      shell: |
        hostIP=$(hostname -I | awk '{print $1}')
        sed -i 's/^Hostname=.*/Hostname=$hostIP/g' /etc/zabbix/zabbix_agentd.conf

    - name: 启动并启用 Zabbix agent
      systemd:
        name: zabbix-agent
        state: started
        enabled: true

    - name: 检查 Zabbix agent 状态
      command: systemctl status zabbix-agent
      register: agent_status
      ignore_errors: yes

    - name: 显示 Zabbix agent 状态
      debug:
        msg: "{{ agent_status.stdout_lines }}"
```







