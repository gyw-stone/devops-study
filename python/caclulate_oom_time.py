# dmesg | grep -i oom 查看前缀，比如2940440.385615
# 宿主机查看启动时间 uptime -s,替换掉strptime的时间
# -*- coding: UTF-8 -*-
import sys
from datetime import datetime, timedelta

def get_time(seconds):
  boot_time = datetime.strptime("2025-07-08 02:29:48", "%Y-%m-%d %H:%M:%S")
  delta = timedelta(seconds=seconds)
  event_time = boot_time + delta
  return event_time
def main():
  if len(sys.argv) < 2:
      print("用法: python3 caclulate_oom_time.py <seconds_since_boot>")
      sys.exit(1)

  try:
      seconds = float(sys.argv[1])
      event_time = get_time(seconds)
      print("OOM 时间为：", event_time)
  except ValueError:
      print("请输入整数秒数")

if __name__ == "__main__":
    main()
  
