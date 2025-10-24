背景：ingress nginx为helm安装，不想过多影响nginx 服务，所以采取cronjob的方式操作nginx pod
先kubectl apply -f rbac.yaml
再创建crobjob
## rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-logrotate
  namespace: test-nginx
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-exec
  namespace: test-nginx
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "exec"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-exec-binding
  namespace: test-nginx
subjects:
  - kind: ServiceAccount
    name: nginx-logrotate
    namespace: test-nginx
roleRef:
  kind: Role
  name: pod-exec
  apiGroup: rbac.authorization.k8s.io

## cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nginx-log-rotate
  namespace: test-nginx
spec:
  schedule: "0 1 * * *"  # 每天9点执行
  jobTemplate:
    spec:
      ttlSecondsAfterFinished: 100 # 执行完后自动删除
      template:
        spec:
          containers:
          - name: rotate
            image: bitnami/kubectl:latest
            command:
              - /bin/sh
              - -c
              - |
                for pod in $(kubectl get pod -n test-nginx -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[*].metadata.name}'); do
                  echo "[INFO] Rotating logs in $pod"
                  kubectl exec -n test-nginx $pod -c controller -- sh -c '
                    log_dir="/var/log/nginx"
                    cd "$log_dir" || exit 0
                    if [ -f access.log ]; then
                          gzip -c access.log > access.log.$(date +%F-%H%M).gz
                          truncate -s 0 access.log
                    fi
                    ls -1t access.log.* 2>/dev/null | tail -n +6 | xargs -r rm -f
                  '
                done
          restartPolicy: OnFailure

