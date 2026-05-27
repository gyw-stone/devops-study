```
# rac1 
172.16.200.148 rac1-priv 
172.16.200.248 rac1
172.16.200.238 rac1-vip
172.16.200.228 rac1-scan
# rac2 
172.16.200.154 rac2-priv
172.16.200.249 rac2
172.16.200.239 rac2-vip
172.16.200.229 rac2-scan
```

```
# oracle19 依赖包安装
yum install -y \
  bc \
  binutils \
  compat-libcap1 \
  compat-libstdc++-33 \
  elfutils-libelf \
  elfutils-libelf-devel \
  fontconfig-devel \
  glibc \
  glibc-devel \
  ksh \
  libaio \
  libaio-devel \
  libX11 \
  libXau \
  libXi \
  libXtst \
  libXrender \
  libXrender-devel \
  libgcc \
  libstdc++ \
  libstdc++-devel \
  libxcb \
  make \
  smartmontools \
  sysstat \
  net-tools \
  unzip \
  nfs-utils \
  gcc \
  gcc-c++
```

```
# 用asm
# 创建用户组
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba

# 创建用户并加入组
useradd -u 54321 -g oinstall -G dba,asmdba,backupdba,dgdba,kmdba,racdba,oper oracle 
useradd -u 54331 -g oinstall -G dba,asmdba,asmoper,asmadmin,racdba grid

# 设置用户密码
echo "oracle" | passwd oracle --stdin
echo "grid" | passwd grid --stdin
```

```
# 创建目录
mkdir -p /u01/app/19.3.0/grid
mkdir -p /u01/app/grid
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1

chown -R grid:oinstall /u01
chown -R oracle:oinstall /u01/app/oracle
chmod -R 775 /u01/
```

```
# 用户安全设置
cat >/etc/security/limits.d/30-oracle.conf<<EOF
grid  soft  nproc 16384
grid  hard  nproc 16384
grid  soft  nofile 1024
grid  hard  nofile 65536
grid  soft  stack 10240
grid  hard  stack 32768
oracle soft nproc 16384
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack  10240
oracle hard stack  32768
oracle hard memlock 3145728
oracle soft memlock 3145728
EOF

cat>>/etc/security/limits.d/20-nproc.conf<<EOF
* - nproc 16384
EOF
```

```
# node1 环境变量
# grid用户
cat>>/home/grid/.bash_profile<<'EOF'
# oracle grid
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=node1.racdb.local
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export ORACLE_SID=+ASM1
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF

# oracle用户
cat>>/home/oracle/.bash_profile<<'EOF'
# oracle
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=node1.racdb.local
export ORACLE_UNQNAME=racdb
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=racdb1
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF
```

```
# node2环境变量设置
# grid用户
cat>>/home/grid/.bash_profile<<'EOF'
# oracle grid
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=node2.racdb.local
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export ORACLE_SID=+ASM2
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF

# oracle用户
cat>>/home/oracle/.bash_profile<<'EOF'
# oracle
export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=node2.racdb.local
export ORACLE_UNQNAME=racdb
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=racdb2
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF
```

```
# 节点免密node1
su - grid
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
ssh-copy-id node2
 
su - oracle
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
ssh-copy-id node2
```

```
# 节点免密node2
su - grid
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
ssh-copy-id node1
 
su - oracle
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
ssh-copy-id node1
```

```
# 巨页关闭
# 创建systemd文件
cat > /etc/systemd/system/disable-thp.service <<EOF

[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl enable --now disable-thp
```

```
# 安装grid
```

