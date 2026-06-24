# 1.查看docker启动命令
docker inspect --format "docker run -d {{.Config.Image}} {{join .Config.Cmd \" \"}}" container_name
runlike -p container_name
# 2.docker-compose 只重启一个服务
docker-compose up -d --no-deps --force-recreate drone-runner
