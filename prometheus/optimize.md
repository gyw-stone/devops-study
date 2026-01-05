## 分析当前prometheus的状态来优化
1.TSDB分析工具
# 分析 TSDB 状态
promtool tsdb analyze /data
# 检查块信息
promtool tsdb list /data
# 导出TSDB 信息
promtool tsdb dump /data > dump.txt

2.pprof 进行性能分析
# 启用pprof 
curl -s "http://serverip:9090/debug/pprof/heap?debug=1" > heap.pprof
# go pprof分析
go tool pprof -http=:8080 heap.pprof 
# 浏览器直接访问
http://serverip:9090/debuf/pprof/
