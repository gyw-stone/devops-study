新建硬盘挂载

lsblk
Name: 分区
Size: 分区大小
mountpoint：挂载点

步骤：

1.新建硬盘

2.虚拟机硬盘分区

```she
fdisk /dev/sdb # fdisk 瓶颈是2T后不可扩容，用gdisk 支持
# 执行后的相关操作,开始分区后输入n，新增分区，然后选择p，分区类型为主分区，两次回车默认剩余全部空间，最后输入w写入分区并退出
```

3.虚拟机硬盘分区格式化

`mkfs.xfs -f /dev/sdb1`

4.将磁盘挂载到其它目录/data/

`mount /dev/sdb1 /data/`

5.永久挂载,写入/etc/fstab或者/etc/rc.local

`/dev/sdb1	/data	xfs	defaults,usrquota,grpquota	0 0`

`mount -a`无报错后重启`reboot`. 若报错则会进入救援模式，把/etc/fstab下添加的那一行注释重启即可

<h3> 扩容
<h4> 方式一 建议
growpard /dev/nvemen1 1 # nvemen1p1 分区扩容
xfs_grow /data # 挂载的目录是data 这样更方便
<h4> 方式二
使用命令：`parted`

1.扩容准备：保证文件系统有多余的空间，以及umount所需要扩容的分区

2.使用parted命令打开磁盘分区表

```bash
sudo parted /dev/sdb
```

3.使用 `print` 命令查看当前的分区情况。找到文件系统所在分区的编号和起始扇区。例如，如果您的文件系统所在分区是 `/dev/sdb1`，您可以看到类似以下的输出：

```
Number  Start   End     Size    Type     File system     Flags
 1      2048s   4095s   2048s   primary  ext4            boot
```

记下起始扇区值（Start value），以备后用。（建议多操作这一步）

4.使用 `resizepart` 命令调整分区大小。

```bash
resizepart 1 -1
```

这将将分区1的大小调整为使用所有可用的空间，-1 表示使用所有空闲空间。

5.调整文件系统大小以适应新的分区大小。不同的文件系统使用的命令不一致

```bash
# ext2，3，4
sudo resize2fs /dev/sdb1
# xfs
sudo xfs_growfs /dev/sdb1
# ntfs
sudo ntfsresize /dev/sdb1
```

6.重新挂载并验证

<h3> 磁盘配额

<h4>注意

1.限制的用户和用户组，只能是普通用户和用户组
2.只能针对分区，不能针对某个目录
3.可以限制容量，也可以限制文件个数
4.软限制可以超过，硬限制不能超过，软限制宽限时间默认7天

<h4>准备工作

检查是否为独立的文件系统

```shell
[root@localhost ~]# df -h /home
Filesystem     Size  Used Avail Use% Mounted on
/dev/hda3      4.8G  740M  3.8G  17% /home  <-- /home 确实是独立的！
```

检查是否不是VFAT文件系统（此文件系统不支持配额）

```shell
[root@localhost ~]# mount | grep home
/dev/hda3 on /home type ext3 (rw)
```

<h4>挂载

1.临时

```she
[root@localhost ~]# mount -o remount,usrquota,grpquota /home
[root@localhost ~]# mount | grep home
/dev/hda3 on /home type ext3 (rw,usrquota,grpquota)
```

2.永久`vim /etc/fstab`

```she
# 编辑
/dev/hda3  /home ext3 defaults,usrquota,grpquota 0 0
```

<h4>扫描文件系统简历quota记录文件

```she
quotacheck [-avugfM] 文件系统
```

<h4>启动

```she
# 同时启动用户和群组的quota服务,关闭为quotaoff,仅第一次需要开启，后续/etc/init.d默认开启
quotaon -auvg
# 只针对用户启动/home的quota服务
quotaon -uv /home
```

<h4>修改配额

三种格式：

```shell
# 1.edquota [-u 用户名] [-g 群组名]
edquota -u test111
Disk quotas for user myquota (uid 710):
  Filesystem    blocks  soft   hard  inodes  soft  hard
  /dev/hda3         80     0      0      10     0     0
  
# 2.edquota -t

# 3.edquota -p 源用户名 -u 新用户名
```

| **选项**  | **功能**                                                   |
| --------- | :--------------------------------------------------------- |
| -u 用户名 | 进入配额的 Vi 编辑界面，修改针对用户的配置值；             |
| -g 群组名 | 进入配额的 Vi 编辑界面，修改针对群组的配置值；             |
| -t        | 修改配额参数中的宽限时间；                                 |
| -p        | 将源用户（或群组）的磁盘配额设置，复制给其他用户（或群组） |

配额限制信息：

filesystem: 针对哪个分区

blocks: 磁盘容量，建议不要手动修改，为quota自动计算，单位K

soft: 软限制(inodes之前为磁盘空间，之后为文件数量)

hard: 硬限制

inodes: 文件数量

<h4>非交互式设置磁盘配额

setquota: 好处不用和管理员交互设定

格式：`setquota -u 用户名 容量软限制 容量硬限制 个数软限制 个数硬限制 分区名`

ps: `setquota -u lamp4 10000 20000 5 8/disk`

<h4> 查询

quota [-ugvs] [用户名或组名]

- -u: 用户名
- -g: 组名
- -v: 显示详细信息
- -s: 以习惯单位显示容量

repquota [-augvs] [分区名]

- -a：依据 /etc/mtab 文件查询配额。如果不加 -a 选项，就一定要加分区名；
- -u：查询用户配额；
- -g：查询组配额；
- -v：显示详细信息；
- -s：以习惯单位显示容量太小；

<h4> xfs限制配额
</h4>

1.检查安装包xfsprogs，若无则安装

```she
rpm -qa | grep xfsprogs
# 安装
yum install xfsprogs
```

2.再检查quota组件

`rpm -ql xfsprogs | grep quota`

3.关闭增强型安全功能，centos6不关闭配额写入会失败

`setenforce 0`

4.挂载设置, `vim /etc/fstab

```shell
/dev/sdb1	/opt/opt	xfs		defaults,usrquota,grpquota	0 0
```

/dev/sdb1: 分区

/opt/opt: 挂载目录

xfs: 使用的文件系统

5.检查是否生效

`mount`

若未生效，进行卸载并挂载

```she
umount /opt/opt
mount -a
```

6.限制操作

```she
xfx_quota -x -c 'limit -u bsoft=50M bhard=80M isoft=4 ihard=6 test111' /opt/opt'
```

```she
限制值设定方式(配额方案)
命令格式：xfs_quota  -x  -c  "指令"  [挂载点]
xfs_quota -x -c ‘limit  [-ug] b[soft|hard]=N i[soft|hard]=N name’
xfs_quota -x -c ‘timer  -ug] [-bir] Ndays’
选项与参数:
limit :实际限制的项目,可以针对 user/group 来限制,限制的项目有
bsoft/bhard : block 的 soft/hard 限制值,可以加单位
isoft/ihard : inode 的 soft/hard 限制值
name: 就是用户/群组的名称
timer :用来设定 grace time 的项目喔,也是可以针对 user/group 以及 block/inode 设定
查询命令
列出目前系统的各的文件系统,以及文件系统的 quota 挂载参数支持       
       xfs_quota   -x   -c  "print"     显示状态信息
列出目前目录的所有用户的 quota 限制值
       xfs_quota -x -c "report -ubih" 目录名
列出目前支持的 quota 文件系统是否有起动了 quota 功能?
       xfs_quota  -x  -c  "state"

project 的限制 (针对目录限制)
1.规范目录、项目名称(project)与项目 ID
  echo "11（ID标识符）:/xfsquota/myquota（目录）" >> /etc/projects
  echo "myquotaproject（项目名称自取）:11（ID标识符）" >> /etc/projid
2.初始化专案名称
     xfs_quota -x -c "project -s myquotaproject（项目名称）"
3.其他
```


<h3>实现基于目录的配额

参考文献：[Linux Disk Quota实践 – 智汇云技术社区 (360.cn)](https://zyun.360.cn/blog/?p=2148)

前期准备：确定selinux关闭

```she
# 查看selinux状态
sestatus -v
# 临时关闭
setenforce 0
# 永久关闭方法一
vim /etc/selinux/conig
SELINUX=disabled
# 永久关闭方法二
sed -i 's/SELINUX=enabled/SELINUX=disabled/g' /etc/selinux/config
```

1. 添加quota激活选项，基于需求，添加usrquota（用户配额），grpquota（组配额），prjquota（项目配额）。这里使用的是prjquota

```shell
# vi /etc/fstab
/dev/sdb1	/data	xfs	defaults,prjquota	0 0
```

2. 挂载目录

   ```shel
   # 避免已挂载
   umount /data
   # 检查是否有错误
   mount -a
   # 无错误后重启机器
   reboot
   # 重启后检查
   mount | grep data
   /dev/sdb1 on /data type xfs (rw,relatime,attr2,inode64,prjquota)
   ```

3. 查看配额是否开启

​	<img src="/Users/apple/Desktop/wiki图片存放/image-20230608150035528.png" alt="image-20230608150035528" style="zoom:50%;" />

4. 创建目录和项目名对应关系

   ```shell 
   ##创建项目id与目录的对应关系
   echo "1:/data/testdata" >> /etc/projects
   ##创建项目id与项目名称的对应关系，即给项目id起个别名
   echo "testdata:1" >> /etc/projid
   ```

   初始化项目语句如下：

   ```shell
   # xfs_quota -x -c "project -s testdata"
   Setting up project testdata (path /data/testdata)...
   Processed 1 (/etc/projects and cmdline) paths for project testdata with recursion depth infinite (-1).
   Setting up project testdata (path /data/testdata)...
   Processed 1 (/etc/projects and cmdline) paths for project testdata with recursion depth infinite (-1).
   Setting up project testdata (path /data/testdata)...
   Processed 1 (/etc/projects and cmdline) paths for project testdata with recursion depth infinite (-1).
   ```

   查看目录是否存在对应项目：

   ```she
   # xfs_quota -x -c "print" /data
   Filesystem          Pathname
   /data               /dev/sdb1 (pquota)
   /data/testdata     /dev/sdb1 (project 1, testdata)
   ```

   5. 设置目录quota大小

      ```shel
      ##针对项目mysqldata设置10M容量硬限制
      # xfs_quota -x -c "limit -p bsoft=6M bhard=10M testdata" /data
      
      ##查看是否生效，以及使用情况
      # xfs_quota -x -c "report -bih" /data
      Project quota on /data (/dev/sdb1)
                              Blocks                            Inodes
      Project ID   Used   Soft   Hard Warn/Grace     Used   Soft   Hard Warn/Grace
      ---------- --------------------------------- ---------------------------------
      #0            20M      0      0  00 [------]      4      0      0  00 [------]
      testdata       0     6M    10M  00 [------]      1      0      0  00 [------]
      ```

      说明：

      ​	bsoft : 软限制，bsoft可以超过，但必须小于bhard，宽限期为7天（默认），超过7天容量都在bsoft和bhard直接，会拒绝继续写入

      ​	bhard : 硬限制，超过即不能写入

      6. 编辑nfs配置文件

         ```shel
         # vim /etc/exports
         /data/testdata 172.26.0.0/16(insecure,rw,sync,no_root_squash)
         # 保证所有用户都有权限
         chmod 777 /data/testdata
         ```

      7. client端挂载

         ```shel
         # client端必须存在testdata
         mkdir -p /data/testdata
         mount -t nfs 172.26.24.72:/data/testdata /data/testdata
         ```

      8. Client测试

         ```she
         # client端进入/data/testdata下
         dd if=/dev/zero of=/data/testdata/test bs=1M count=15
         ```

![image-20230608151709199](/Users/apple/Desktop/wiki图片存放/image-20230608151709199.png)					

9. 相关操作

```she
# server端查询使用情况,2种均可
xfs_quota -x -c "df -h" /data
xfs_quota -x -c "report -h" /data
# client端查询
df -h /data/testdata
# 调整容量限制
xfs_quota -x -c "limit -p bsoft=100M bhard=100M testdata" /data
```
