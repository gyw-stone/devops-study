1.备份与恢复
# 备份
mysqldump -h domain -P 3306 -u username -p --single-transaction --set-gtid-purged=OFF wallet_blog > wallet_blog_backup_20260527.sql
# 恢复
docker exec -i ghost-mysql mysql -u username -p mypassword wallet_blog < /home/ec2-user/wallet_blog_backup_1.sql
