#!/bin/bash
set -e

WG_PASSWORD="ffTXHSO15Cbi5j2z"
WG_HOST="dev.wg.cctip.io"
WG_DEFAULT_DNS="8.8.8.8"
WG_DEFAULT_ADDRESS="10.0.2.x"
WG_ALLOWED_IPS="10.0.2.0/24,172.17.0.0/16"
WG_PERSISTENT_KEEPALIVE="25"

echo "==> 更新 apt 并安装 Docker..."
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

if ! command -v docker >/dev/null 2>&1; then
  echo "==> 添加 Docker 官方 GPG 密钥..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo "==> 添加 Docker 仓库..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
  echo "==> Docker 已安装，跳过安装步骤"
fi

echo "==> 启动 Docker 服务并设置开机自启"
sudo systemctl enable docker
sudo systemctl start docker

# 容器端口映射配置
declare -a UDP_PORTS=(443 445 446 447 448 449)
declare -a HTTP_PORTS=(10000 10001 10002 10003 10004 10005)

for i in "${!UDP_PORTS[@]}"; do
  NAME="wg-easy-${UDP_PORTS[$i]}"
  echo "==> 启动容器 $NAME (UDP端口: ${UDP_PORTS[$i]}, HTTP端口: ${HTTP_PORTS[$i]})"

  # 先停止已存在同名容器
  if sudo docker ps -a --format '{{.Names}}' | grep -q "^${NAME}$"; then
    sudo docker rm -f "$NAME"
  fi

  sudo docker run -d \
    --name "$NAME" \
    -e PASSWORD="$WG_PASSWORD" \
    -e WG_HOST="$WG_HOST" \
    -e WG_DEFAULT_DNS="$WG_DEFAULT_DNS" \
    -e WG_DEFAULT_ADDRESS="$WG_DEFAULT_ADDRESS" \
    -e WG_ALLOWED_IPS="$WG_ALLOWED_IPS" \
    -e WG_PERSISTENT_KEEPALIVE="$WG_PERSISTENT_KEEPALIVE" \
    -v /data/.wg-easy:/etc/wireguard \
    -p "${UDP_PORTS[$i]}":51820/udp \
    -p "${HTTP_PORTS[$i]}":51821/tcp \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_MODULE \
    --sysctl net.ipv4.conf.all.src_valid_mark=1 \
    --sysctl net.ipv4.ip_forward=1 \
    --restart unless-stopped \
    weejewel/wg-easy
done

echo "==> WireGuard 容器启动完成"
