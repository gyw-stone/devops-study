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

```
CPU: 1319
内存：4887.5
磁盘：系统盘：13110 + 数据盘：45764

awk -F'(' '{for(i=2; i<=NF; i++) printf "%s ", $i; print ""}' tests >test11
grep -oP '[0-9]+\)' test11 | cut -d ')' -f1 >test22
awk '{sum += $1} END {print "Total sum of numbers:", sum}' test22

```

```
k8s应聘面试经常问： 
一、Kubernetes的 Operator 操作步骤是什么？   
二、   K8S如何定义步骤crd CustomResourceDefinitions，  三、K8S版本升级步骤？  四 K8S迁移？、五、K8S各个组件优化？  六 、 在K8S集群里安装mysql主从复制 步骤？， 七、K8S使用第三方网络插件如何定制网络策略步骤？  八、K8S证书变成10年证书步骤是什么？ 九、 监控软件监控k8s什么指标，监控安装步骤 ？ 等等
```

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: im-dev-30-ryt-pv
spec:
  capacity:
    storage: 500Gi
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Retain
  accessModes:
    - ReadWriteMany
  nfs:
    path: /data/hdd2/nfs_data/im_test/im_dev_30_ryt
    server: 172.26.22.48
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: im-dev-30-ryt-pvc
  namespace: im-dev-30-ryt
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 500Gi
```



