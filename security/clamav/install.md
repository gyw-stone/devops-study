# 安装
apt install clamav -y 
# 使用
clamscan /var/log
# cli
# clamav cli
sudo nice -n 19 ionice -c 3 clamscan -r  / -i -l /var/log/clamd.scan \
  --exclude-dir="^/sys" \
  --exclude-dir="^/proc" \
  --exclude-dir="^/dev" \
  --exclude-dir="^/run" \
  --exclude-dir="^/var/lib/docker" \
  --exclude-dir="^/var/lib/kubelet" \
  --exclude-dir="^/var/lib/containers" \
  --exclude="\.(mp4|avi|mkv|mov|flv|wmv|mp3|flac|wav|ogg|jpg|jpeg|png|gif|bmp|iso|img|tar\.gz|tar\.bz2)$" \
  --max-filesize=50M \
  --max-scansize=100M \
  --scan-elf=yes \
  --scan-ole2=yes
