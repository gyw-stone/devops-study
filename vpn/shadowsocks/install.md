# server
# ubuntu
sudo apt install pipx
pipx ensurepath
pipx install 'git+https://github.com/shadowsocks/shadowsocks.git@master'
# centos
yum install python-setuptools && easy_install pip
pip install git+https://github.com/shadowsocks/shadowsocks.git@master

# other ref: https://github.com/shadowsocks/shadowsocks/tree/master

# shadowsocks.service
mkdir -p /etc/shadowsocks
cat >>/etc/shadowsocks/shadowsocks.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":443,
    "password":"lai2240881",
    "timeout":600,
    "method":"aes-256-cfb",
    "mode": "tcp_and_udp"
}
EOF

vim /etc/systemd/system/shadowsocks.service
cat >>/etc/systemd/system/shadowsocks.service <<EOF
[Unit]
Description=Shadowsocks
[Service]
TimeoutStartSec=0
ExecStart=/home/ubuntu/.local/bin/ssserver -c /etc/shadowsocks/shadowsocks.json
[Install]
WantedBy=multi-user.target
EOF

systemctl enable shadowsocks.service
systemctl start shadowsocks.service
systemctl status shadowsocks.service 

### client
sudo apt install shadowsocks-libev
mkdir /etc/shadowsocks-libev/
cat >>/etc/shadowsocks-libev/shadowsocks.json <<EOF
{
    "server":"linuxsa.org",
    "server_port":443,
    "local_port":1080,
    "password":"lai2240881",
    "timeout":600,
    "method":"aes-256-cfb",
    "fast_open": false,
    "workers": 1
}
EOF

# 自启动与上面一致，更改配置文件，启动命令是sslocal
# 测试是否正常运行
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip 
若Shadowsock客户端已正常运行，则结果如下：

    {
      "origin": "x.x.x.x"       #你的Shadowsock服务器IP
    }
## 转发http,https ref:https://linuxchina.net/index.php/CentOS7.x%E5%AE%89%E8%A3%85%E9%85%8D%E7%BD%AEShadowsocks%E5%AE%A2%E6%88%B7%E7%AB%AF%E7%BB%88%E7%AB%AF%E7%BF%BB%E5%A2%99#privoxy
## vpn代理
shadowsocks + WSS + nginx + cdn