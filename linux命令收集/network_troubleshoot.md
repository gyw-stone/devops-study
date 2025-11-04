1.验证 nginx 解析问题追踪,前提服务正常
## curl 测试链路,lb侧 以及 ingress pod 侧
curl -X POST -H "Host: cwallet.com" http://k8s-cctipngi-cctipngi-0e85a52c0e-5501c1a91f1f56aa.elb.ap-northeast-1.amazonaws.com/cctip/v1/wallet_swap/swap/quote
curl -X POST -H "Host: cwallet.com" http://127.0.0.1:80/cctip/v1/wallet_swap/swap/quote
## 验证 NLB 直连
curl -svo /dev/null -k https://archery-8fa8efdc6757d2c8.elb.ap-northeast-1.amazonaws.com --resolve '*:443:13.159.38.28'
2.网络丢包定位
mtr -nzrw -c 60 -m 60 <IP>
 hping 
 traceroute 等工具
