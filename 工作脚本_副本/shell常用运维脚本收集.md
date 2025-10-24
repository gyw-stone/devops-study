<h4>
  1.循环从文件中ping主机
</h4>

```she
#!/bin/bash

# 创建一个新文件来保存 ping 通的主机
touch reachip.txt downip.txt
#max_threads=20
# 从文件中读取每一行
while read line; do
# 使用 ping 命令测试主机是否可达
        ping -c 1 "$line" > /dev/null &
        #if [ $(jobs | wc -l) -ge "$max_threads" ];then
        #       wait -n
#       fi              
      # 检查 ping 命令的退出状态码
        if [ $? -eq 0 ]; then
            echo "$line is up"
        # 如果主机可达，将其写入文件 reachable.txt
            echo "$line" >> reachip.txt
      else
          echo "$line is down"
          echo "$line" >> downip.txt
    fi
done < alihost.txt

```

<h4>2、判断文件不同值

```python
def file_diff(file1,file2,file3):
    """ 用for 循环判断file1中的值不在file2中，并写入到file3中,且每一行就一个值 """
    with open(file1, 'r') as f1, open(file2, 'r') as f2, open(file3, 'w') as f3:
        # 读取file2中的所有值到一个集合中
        file2_values = set(line.strip() for line in f2)

        # 遍历file1中的每个值
        for line in f1:
            value = line.strip()

            # 如果该值不在file2中，则写入到file3中
            if value not in file2_values:
                f3.write(value + '\n')
if __name__=="__main__":
    file2 = '/Users/apple/fsdownload/downip.txt'
    file1 = '/Users/apple/PycharmProjects/pythonProject1/zabbix_not_ok.txt'
    file3 = 'zabbix_not_fin.txt'
    file_diff(file1,file2,file3)
```

<h4>3、从文件中清理harbor制品

```yaml
#!/bin/bash
# harbor 1.7版本
harbor_url="https://dockerhub.datagrand.com"
harbor_username="admin"
harbor_password="AYLyR89wmmMlVFwa"
delete_file="2_delete.txt"
max_threads=20

while IFS= read -r image; do

    curl -u "$harbor_username:$harbor_password" -X DELETE "$harbor_url/api/repositories/$image" &
    if [ $(jobs | wc -l) -ge "$max_threads" ];then
    	wait
    fi  
   
    echo "镜像已删除：$image" >> already_delete.txt

done < "$delete_file"

```

```shell
#!/bin/bash

harbor_url="https://dockerhub.datagrand.com"
harbor_username="admin"
harbor_password="AYLyR89wmmMlVFwa"
delete_file="2_delete.txt"
max_procsses=20 # 最大进程数
# 设置Cookie文件保存登录信息
cookie_file=$(mktemp) 
# 第一次登录获取Cookie
curl -c $cookie_file -u "$harbor_username:$harbor_password" $harbor_url

while IFS= read -r image; do
  # 使用Cookie保持会话
  curl -b $cookie_file -X DELETE "$harbor_url/api/repositories/$image" && echo "镜像已删除:$image" >> already_delete.txt &
    ps -p $! > /dev/null
    # 大于20则等待
    if [ $processes -ge $max_processes ]; then
  			wait
        # 控制进程数
        processes=$((processes-1))
  	fi
  			processes=$((processes+1))

done < "$delete_file"
[ -e /opt/shell/new/$cookie_file ] && rm $cookie_file
```

<h4>4、shell筛选文本中出现几次以上的数据</h4>

```yaml
# 文件名
read -p "请输入文件详细路径：" filename 
read -p "请输入筛选出现的次数：" count
# filename="test"

# 使用awk计数每个机器的出现次数，然后使用sort进行排序
counts=$(awk '{print $1}' "$filename" | sort | uniq -c)

# 使用grep筛选出现3次的机器
machines=$(echo "$counts" | awk '$1 == $count {print $2}')

# 打印结果
echo "Machines appearing 3 times: $machines"
```

<h4>5、备份脚本</h4>

```shell
#!/bin/bash

# 设置备份源目录
backup_dir="/data/go-ldap-admin-main/docs/"
# 备份的目标目录
backup_file="/data/backup/go-ldap-admin-main/"
# 设置日志名
log_file="rsync_$(date +\%Y\%m\%d).log"
if [ -e $backup_file ];then 
	break
else
	# 文件目录不存在创建
	mkdir -p $backup_file
fi

# 执行备份命令
echo "Step 1: $(date) - Rsync Start #####" | tee -a "$log_file"
echo "Step 2: Rsync Starting....."
rsync -avzP --delete --stat $backup_dir $backup_file>>rsync_$(date +\%Y\%m\%d).log;
echo "Step 3: $(date) - Rsync Done #####" | tee -a "$log_file"
```

<h4> 6、linux开用户</h4>

```
# 实现把公钥自动拷贝到对应的用户下，仅支持新创用户
#!/bin/bash
read -p "请输入你需要添加的用户名：" a
read -p "请输入该用户的个人公钥：" b
useradd -d /data/$a -m $a
mkdir -p /data/$a/.ssh
ssh-keygen -t rsa -f /data/$a/.ssh/id_rsa -q -N "" -C "$a@iz2zea0oa5idui0qvvh797z"
cd /data/$a/.ssh && touch authorized_keys
c=`cat /data/$a/.ssh/id_rsa.pub`
echo "$b" >> /data/$a/.ssh/authorized_keys
echo "$c" >> /data/$a/.ssh/authorized_keys
chown -R $a. /data/$a/.ssh
chmod 700 /data/$a/.ssh
chmod 600 /data/$a/.ssh/authorized_keys
d=`cat /data/$a/.ssh/authorized_keys`
echo $d
```

