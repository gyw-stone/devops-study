```
# 清除节点
kubectl drain --ignore-daemonsets <node name> --delete-emptydir-data --force
kubectl delete <node name>
# 移除那个master节点执行
kubeadm reset
# key
kubeadm init phase upload-certs --upload-certs
# token
kubeadm token create --print-join-command
# key 和token 拼接后执行
```

```
# 列出当前服务器的僵尸进程
ps -A -ostat,pid,ppid | grep -e '[zZ]'
# 给当前目录下的所有目录添加执行权限
find . -type d -exec chmod a+w {} \;
```

```
---
- name: Deploy Node Exporter Container
  hosts: your_target_host_or_group
  become: yes
  tasks:
    - name: Run Node Exporter Container
      docker_container:
        name: node-exporter
        image: dockerhub.datagrand.com/monitor/node-exporter:v1.5.0
        detach: yes
        ports:
          - "9100:9100"
        network_mode: host
        pid_mode: host
        volumes:
          - "/:/host:ro,rslave"
```

```
docker run -d \
-p 9090:9090 \
--name prometheus-test \
-v  /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
prom/prometheus \
--restart=always \
--config.file=/etc/prometheus/prometheus.yml --web.enable-lifecycle
```

```
if $msg contains "rec_online" then {
    if $syslogfacility-text == "local1" then  /data3/log_collect/rec_online_log/root.log
    if $syslogfacility-text == "local2" then /data3/log_collect/rec_online_log/warn.log
    if $syslogfacility-text == "local3" then /data3/log_collect/rec_online_log/info.log
    stop
}
```

```
00 03 * * * /usr/bin/docker system prune -af
0 */1 * * * /usr/bin/docker image prune -f
0 */1 * * * /usr/bin/docker container prune -f
```

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv_ganyunliang
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  persistentVolumeReclaimPolicy: Retain
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /data/sdv1/k8s_nfs/pv_ganyunliang
    server: 192.168.46.212
```

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: kunpeng-dev01-storage
reclaimPolicy: Retain
provisioner: kubernetes.io/nfs
parameters:
  nfsServer: 192.168.46.212
  nfsPath: /data/sdv1/k8s_nfs/
```

```
mount.ceph ceph--51bde783--91b1--42ea--8c6a--78c831e54857-osd--block--461a9614--d706--45e6--83fc--357026187867 /data1 -o name=admin,secret=QDVSTRiyWqGAxAAk3PWH8Ad0+a0rDG31pfldg==
```

```
# 查看有效期
grep 'client-certificate-data' .kube/config | awk '{print $2}' | base64 -d | openssl x509 -text | grep Validity -A2
```

```
kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}' | base64 -d
```

```
1.查看IP是否同一网段，子网掩码是否255.255.255.0,检查网关
ipconfig /all
2.路由检查
route print
3.检查防火墙
netsh advfirewall show allprofiles
4.机器互ping
```

```
 kubectl exec -it -n kube-system calico-node-* -- grep 'router id' /etc/calico/confd/config/bird.cfg
 
 kubectl get pods -n kube-system -l k8s-app=calico-node -o jsonpath='{.items[*].metadata.name}' |tr ' ' '\n' | xargs -I {} sh -c 'echo "Checking router id in pod {}"; kubectl exec -n kube-system {} -- grep "router id" /etc/calico/confd/config/bird.cfg | grep -v "Defaulted"
calicoctl get bgpconfig default -o yaml
```

```
欧拉修改静态IP文件后执行
# 重加载
nmcli con reload
# 激活网卡
nmcli con up eno4
```





































































































