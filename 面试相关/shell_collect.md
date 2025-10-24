while read user
do
  id $user &>/dev/null
  if [ $? -eq 0 ];then
    echo "user $user already exists"
  else
    useradd $user
    if [ $? -eq 0 ];then
      echo "$user is created."
    fi
done <user.txt




thread=5 # 定义需要的进程数
tmp_fifofile=/tmp/$$.fifo #存放fd的对应文件

mkfifo $tmp_fifofile
exec 8<> $tmp_fifofile
rm $tmp_fifofile
for f in `seq $thread`
do
  echo >&8
done
for i in {1..254}
do
  read -u 8
  {
    ip=192.168.112.$i
    
    ping -c1 -W1 $ip &>/dev/null
    if [ $? -eq 0 ];then
      echo "Success!！"
    else
      echo "Fail!!"
    fi
    echo >&8

  }&

done
wait
exec 8>&- #释放
echo "finish>>>"


## 普通版
#！/usr/bin/expect
spawn ssh root@192.168.122.52 # spawn是产生会话

expect {
  "yes/no" { send "yes\r"; exp_continue } # 获得期望到的值，然后发送命令；exp_continue是循环多次匹配；’\r‘是回车
  "password:" { send "123456\r" };
}
interact # 允许用户交互

## 升级版
#!/usr/bin/expect
set ip [lindex $argv 0] # 设置位置参数，支持传参，输入的参数的第一列
set user [lindex $argv 1] # 输入的参数的第二列
set password centos
set timeout 5 # 设置超时时间，延迟5秒。默认是10秒

spawn ssh $user@$ip # spawn是进入expect的内置命令

expect {
  "yes/no" { send "yes\r"; exp_continue }
  "password:" { send "$password\r" }
}

expect "#"
send "useradd yangyang\r"
send "pwd\r"
send "exit\r"
expect eof



#！/usr/bin/bash

>ip.txt
password=stone

rpm -q expect &>/dev/null
if [ $? -eq 0 ];then
  yum -y install expect &>/dev/null
fi

if [ ! ~/.ssh/id_rsa ];then
  ssh-keygen -P "" -f ~/.ssh/id_rsa
fi

for i in {2..254}
do
  {
  ip=192.168.122.$i
  ping -c1 -W1 $ip &>/dev/null
  if [ $? -eq 0 ];then
    echo "$ip"2>ip.txt
    /usr/bin/expect <<-EOF
    set timeout 10
    spawn ssh-copy-id $ip
    expect {
      "yes/no" { send "yes\r"; exp_continue }
      "password:" { send "$password\r" }
    }
    expect eof
  fi
  }&
done





#!/usr/bin/bash
while read ip
do
  fail_count=0
  for i in {1..3}
  do
    ping -c1 -W1 $ip &>/dev/null
    if [ $? -eq 0 ];then
      echo "$ip ping is ok"
      break
    else
      let fail_count++
  done
  if [ $fail_count -eq 3 ];then
    echo "$ip ping is failure"
  fi
done <ip.txt


