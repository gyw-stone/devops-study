### 实现cronjob 自动curl 监测es的健康状态并发送到fs
apiVersion: batch/v1
kind: CronJob
metadata:
  name: es-red-alert
  namespace: kube-logger
spec:
  schedule: '*/10 2-11 * * *'
  successfulJobsHistoryLimit: 3
  spec:
    ttlSecondsAfterFinished: 100
    template:
      spec:
          containers:
            - command:
                - /bin/sh
                - '-c'
                - >
                  STATUS=$(curl -sS -m 10 -u "elastic:haxi_merchant@2023"
                  http://elasticsearch:9200/_cluster/health | sed -n
                  's/.*"status":"\([^"]*\)".*/\1/p'); echo "Current status:
                  $STATUS"; if [ "$STATUS" = "red" ]; then
                    curl -X POST 'https://open.larksuite.com/open-apis/bot/v2/hook/046b016b-e80e-4bd8-8b1c-9b986a3c3466' \
                        -H 'Content-Type: application/json' \
                        -d '{
                        "msg_type": "text",
                        "content": {
                            "text": "告警通知：es状态为 red，请及时处理！"
                        }
                        }'
                  fi
              image: curlimages/curl:8.6.0
              imagePullPolicy: IfNotPresent
              name: checker
          dnsPolicy: ClusterFirst
          restartPolicy: Never
          securityContext: {}
          terminationGracePeriodSeconds: 30
