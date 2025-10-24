这是一个国产的sql审核平台
helm repo add douban https://douban.github.io/charts/
helm repo update
helm install archery douban/archery -f values.yaml -n archery
kubectl logs --tail=20 -n archery archery-56649c7684-fjgq6   -c init-mysql
helm uninstall archery -n archery
helm upgrade archery douban/archery -f values.yaml -n archery
kubectl get pod -n archery

deployment archery修改 init-mysql为 until nc -z archery-mysql 3306; do echo waiting; sleep 5; done;
避免一直卡在init-mysql这个阶段
FAQ:
1.开放https 输入用户密码登录报错403 csrf
archery env配置
- name: SITE_URL
  value: "https://archery.example.com"
- name: CSRF_TRUSTED_ORIGINS
  value: "https://archery.example.com,http://127.0.0.1"
