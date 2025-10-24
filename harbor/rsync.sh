# 同步一个库的指定镜像到另外一个库，且映射的域名一致，harbor版本不一致
#!/bin/bash
# 文件路径，文本处理后缺失的镜像名
file_path="harbor_images.txt"
# 处理的最大并行任务数
max_parallel=50
# 初始化计数器
count=0
# 读取文件中的每一行
echo "开始执行同步"
while IFS= read -r line; do
  sed -i 's/#172.17.174.254/172.17.174.254/g' /etc/hosts
  # 执行docker pull命令并在后台运行
  docker pull "$line">>pull.log 2>&1 &
  # 增加计数器以跟踪处理的行数
  count=$((count + 1))
  # 检查是否达到最大并行任务数
  if [ "$count" -ge "$max_parallel" ]; then
    # 等待所有后台拉取任务完成
    wait
    sed -i 's/172.17.174.254/#172.17.174.254/g' /etc/hosts
    # 推送之前拉取的镜像
    for image in "${pulled_images[@]}"; do
      docker push "$image">>push.log 2>&1 &
    done
    # 等待所有后台推送任务完成
    wait
    # 删除之前的50个镜像
    docker rmi "${pulled_images[@]}"
    wait
    # 重置计数器和已拉取的镜像列表
    count=0
    pulled_images=()
  else
    # 将已拉取的镜像添加到列表中
    pulled_images+=("$line")
  fi
done < "$file_path"
# 等待所有后台拉取任务完成
wait
# 推送剩余的已拉取镜像
for image in "${pulled_images[@]}"; do
  docker push "$image">>push.log 2>&1 &
done
# 等待所有后台推送任务完成
wait
echo "同步结束"
