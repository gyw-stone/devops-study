```
curl -u "admin:AYLyR89wmmMlVFwa" -X 'GET' "https://dockerhub.datagrand.com/api/v2.0/projects/idps/?repositories?page_size=100" -k -s | yq '.[].name' -"
```

```
{
  "default-runtime": "nvidia",
  "runtimes": {
     "nvidia": {
         "path": "/usr/bin/nvidia-container-runtime",
         "runtimeArgs": []
     }
 },
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-driver": "overlay2",
    "data-root": "/data/docker",
    "storage-opts":["overlay2.override_kernel_check=true"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "oom-score-adjust": -1000,
    "bip": "172.20.0.1/16",
    "fixed-cidr": "172.20.0.0/24",
    "metrics-addr" : "0.0.0.0:9323",
    "experimental" : true,
    "default-address-pools": [
    {"base": "10.252.0.0/24", "size": 24},
    {"base": "10.252.1.0/24", "size": 24},
    {"base": "10.252.2.0/24", "size": 24}]
}

```

```
## 查看当前用了多少个地址
docker network inspect --verbose --format  '{{range .Services}}{{printf "%s\n" .VIP}}{{range .Tasks}}{{printf "%s\n" .EndpointIP}}{{end}}{{end}}' ingress |grep -v '^$' |wc -l
```

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-idps100
spec:
  capacity:
    storage: 300Gi
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Retain
  accessModes:
    - ReadWriteMany
  nfs:
    path: /data/hdd1/nfs_data/guohuanyang/kubernetes
    server: 172.26.22.48
    
```

```
# /etc/network/interface
auto lo
iface lo inet loopback
auto enp2s0
iface enp2s0 inet static
address 172.25.22.10
netmask 255.255.255.0
gateway 172.25.22.1
dns1 61.139.2.69
dns2 114.114.114.114
```

```
docker 代理
mkdir -p /etc/systemd/system/docker.service.d
vim  /etc/systemd/system/docker.service.d/http-proxy.conf
添加：
[Service]
Environment="HTTPS_PROXY=http://172.17.91.102:8118"
Environment="HTTP_PROXY=http://172.17.91.102:8118/"    #可选
Environment="NO_PROXY=127.0.0.1,localhost,*.datagrand.com,*.datagrand.cn"

重启docker
```





















