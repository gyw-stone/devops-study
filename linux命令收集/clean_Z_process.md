## 查看存在的僵尸进程
ps aux | grep Z

USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
root 2275678 0.0 0.0 0 0 ? Z Nov12 0:00 [sh] <defunct> 
root 2933835 0.0 0.0 0 0 ? Z Nov13 0:00 [sh] <defunct> 
## 找父进程
ps -eo pid,ppid,state,cmd | grep defunct

2275678 1583981 Z [sh] <defunct>
2933835 1583981 Z [sh] <defunct>
