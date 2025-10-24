1.修改node_exporter.service文件
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=/var/lib/node_exporter/textfile_collector
Restart=on-failure

[Install]
WantedBy=default.target
EOF

2.重启服务
sudo systemctl daemon-reload
sudo systemctl restart node_exporter.service

3.创建文件
sudo mkdir -p /var/lib/node_exporter/textfile_collector

4.编辑脚本
sudo tee /root/failed_login.sh > /dev/null <<'EOT'
#!/bin/bash
  threshold_epoch=$(date -d '1 min ago' +%s)
  count=$(sudo lastb -n 50 -F | awk -v threshold_epoch="$threshold_epoch" '
  {
    match($0, /[A-Z][a-z]{2} [A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2} [0-9]{4}/, arr);
    if (arr[0] != "") {
      cmd = "date -d \"" arr[0] "\" +%s";
      cmd | getline log_epoch;
      close(cmd);
      if (log_epoch >= threshold_epoch) count++;
    }
  }
  END { print count+0 }')
  if ! [[ $count =~ ^[0-9]+$ ]]; then
    count = 0
  fi
  cat <<EOF > /var/lib/node_exporter/textfile_collector/ssh_fail.prom
  # HELP ssh_failed_login_count SSH failed login attempts in past 1 min
  # TYPE ssh_failed_login_count gauge
  ssh_failed_login_count $count
  EOF
EOT

5.crontab编写
sudo bash -c '(crontab -u root -l 2>/dev/null; echo "* * * * * bash /root/failed_login.sh") | crontab -u root -'