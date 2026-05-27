```
curl -u "user:passwd" -X 'GET' "https://dockerhub.datagrand.com/api/v2.0/projects/idps/?repositories?page_size=100" -k -s | yq '.[].name' -"
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





















