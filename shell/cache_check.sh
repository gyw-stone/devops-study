#!/bin/bash
## 检查是否是缓存问题，如果命中了cache,看最后的age是不是一样,如果一样说明缓存的是基于路径,修改为基于请求
URL1='https://xxx.com/events?archived=false&limit=21&xxxx'
URL2='https://xxx.com/events?archived=false&limit=20&xxxx'
curl --compressed -sS -D h1.txt -o b1.json "$URL1"
curl --compressed -sS -D h2.txt -o b2.json "$URL2"
grep -i 'x-cache\|age\|cache-control' h1.txt h2.txt
