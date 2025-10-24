## 查看某个target状态
curl -s http://172.17.128.37:9090/api/v1/targets |   jq '.data.activeTargets[] | select(.scrapeUrl | contains("172.17.40.37:9100")) | {labels.job, scrapeUrl, lastScrape, lastError,health}'
