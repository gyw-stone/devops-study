```
# 安装zlib1.3依赖
tar xzf zlib.tar.gz && cd zlib-1.3.1/
./configure --prefix=/usr/local/zlib
make -j 8 && make install
# 依赖问题
yum install pam-devel -y

echo "/usr/local/zlib/lib/" >> /etc/ld.so.conf
ldconfig -v
c 
cd /usr/local/zlib/lib/
cp libz.so.1.3.1 /lib64/libz.so.1.3.1
cd /lib64/
ln -snf libz.so.1.3.1 /lib64/libz.so
ln -snf libz.so.1.3.1 /lib64/libz.so.1
# 原来 /lib64/libz.so.1 -> libz.so.1.2.7

## 安装openssh9.7p
# 备份
mkdir /etc/ssh/bak
cp /etc/ssh/ssh* /etc/ssh/bak && cp /etc/ssh/m* /etc/ssh/bak
cd 
cp /etc/pam.d/sshd .

rpm -e `rpm -qa | grep openssh` --nodeps

/root/openssh9.7/openssh-9.7p1
./configure --prefix=/usr/ --sysconfdir=/etc/ssh --with-pam --with-md5-passwords --with-tcp-wrappers --with-ssl-dir=/usr/local/openssl --with-zlib=/usr/local/zlib  --mandir=/usr/share/man
make -j 8 && make install 
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_ecdsa_key
chmod 600 /etc/ssh/ssh_host_ed25519_key

# 配置
cp -p contrib/redhat/sshd.init /etc/init.d/sshd
chmod +x /etc/init.d/sshd
echo "PermitRootLogin yes">>/etc/ssh/sshd_config
sed -i '/UsePAM no/c\UsePAM yes' /etc/ssh/sshd_config
sed -i '/^Subsystem/c\Subsystem sftp /usr/libexec/sftp-server' /etc/ssh/sshd_config
sed -i '/^SELINUX=enforcing/c\SELINUX=disabled' /etc/selinux/config
setenforce 0

sshd -v
/usr/sbin/sshd -p 22

## 设置开机启动
chkconfig --add sshd
chkconfig sshd on
chkconfig --list sshd

# 重启服务
systemctl daemon-reload
systemctl restart sshd

cp sshd /etc/pam.d/
```