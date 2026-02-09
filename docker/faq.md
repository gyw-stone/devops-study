# 1.查看docker启动命令
docker inspect --format "docker run -d {{.Config.Image}} {{join .Config.Cmd \" \"}}" container_name
runlike -p container_name
