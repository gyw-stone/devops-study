## aws linux 系统 x86 安装client
1.开启ip转发
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

2.安装
dnf install wireguard-tools -y

cd /etc/wireguard
vim wg0.conf (server端生成的)
添加路由nat转发等防火墙规则 到 [Interface]

PostUp = iptables -t nat -A POSTROUTING -s 10.0.8.0/24 -o ens5 -j MASQUERADE
PostUp = iptables -A INPUT -p udp --dport 51822 -j ACCEPT
PostUp = iptables -A FORWARD -i wg0 -o ens5 -j ACCEPT
PostUp = iptables -A FORWARD -i ens5 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

PostDown = iptables -t nat -D POSTROUTING -s 10.0.8.0/24 -o ens5 -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport 51822 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o ens5 -j ACCEPT
PostDown = iptables -D FORWARD -i ens5 -o wg0 -m state --state RELATED,ESTABLISHED -j ACCEPT

3.启动 & 停止
wg-quick up wg0
wg-quick down wg0
4.查看状态
wg show

参考文献：
1.https://www.cnblogs.com/yearbbs/articles/18646170
