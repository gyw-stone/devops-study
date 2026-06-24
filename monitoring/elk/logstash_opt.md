1.查看管道与插件的详细耗时
curl -s http://localhost:9600/_node/stats/pipelines?pretty
2.查看logstash 线程与cpu占用
curl -s http://localhost:9600/_node/stats/process?pretty
3.查看当前内存与 JVM 状态
curl -s http://localhost:9600/_node/stats/jvm?pretty



调优参数:
1.加大工人数量,通常为cpu的2-4倍
pipeline.workers: 8
2.调大单次批处理大小
pipeline.batch.size: 2500
3.调大批量等待时间
pipeline.batch.delay: 100
