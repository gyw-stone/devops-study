git安装
yum -y install git (centos7) 
dnf -y install git (rocky)

配置git用户 
git config --global user.name "test"
git config --global user.email "test@163.com"
git config --global color.ui true

创建本地仓库
mkdir /data && cd /data

初始化仓库
git init (ls -a查看出现.git即为成功）


gitlab安装

配置镜像源，已配置跳过
cat >/etc/yum.repos.d/gitlab-ce.repo<<EOF  
[gitlab-ce]
name=gitlab-ce
baseurl=http://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el6
Repo_gpgcheck=0
Enabled=1
Gpgkey=https://packages.gitlab.com/gpg.key

更新本地yum缓存
sudo yum makecache

安装最新版本
yum intall gitlab-ce -y
安装指定版本
sudo yum install gitlab-ce-x.x.x  

修改配置文件
vim /etc/gitlab/gitlab.rb
external_url 'http://ip:8600' #不配置端口默认为80
nginx['listen_port'] = nil 修改为 nginx['listen_port'] = 8600 #设置端口后需修改

防火墙永久开放端口号
firewall-cmd --zone=public --add-port=8600/tcp --permanent

注意：若出现无法访问问题，要么是端口被占用，要么是防火墙关闭了

启动服务和组件
gitlab-ctl reconfigure && gitlab-ctl start

访问http://ip:8600登录gitlab
默认账号 root
默认密码 5iveL!fe



gitlab常用命令
sudo gitlab-ctl start    # 启动所有 gitlab 组件；
sudo gitlab-ctl stop        # 停止所有 gitlab 组件；
sudo gitlab-ctl restart        # 重启所有 gitlab 组件；
sudo gitlab-ctl status        # 查看服务状态；
sudo gitlab-ctl reconfigure        # 启动服务；
sudo vim /etc/gitlab/gitlab.rb        # 修改默认的配置文件；
gitlab-rake gitlab:check SANITIZE=true --trace    # 检查gitlab；
sudo gitlab-ctl tail        # 查看日志；
