## all-in-one 
1.安装indexr
2.安装server
3.安装dashboard
## 一站式脚本
curl -sO https://packages.wazuh.com/4.12/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
4.安装好后会给出dashboard 的 admin 以及密码
5.安装agent 登录dashboard后deploy new agent 会给出命令，去node执行
6.重置密码
cd /usr/share/wazuh-indexer/plugins/opensearch-security/tools
./wazuh-passwords-tool.sh -u admin -p "kz0+SpcaI1g8Q1k0PYgk5+pjw?jHDVGX"
密码备份文件存放在: /etc/wazuh-indexer/internalusers-backup
