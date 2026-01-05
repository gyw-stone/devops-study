## 适用ssh连不进去的办法
1.走串行控制台(vnc)连接
2.输入用户密码
3.如果密码，关机，修改用户数据，贴入下面字段，重启

Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-config; charset="us-ascii"
#cloud-config
cloud_final_modules:
- [scripts-user, always]
--==BOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
echo -e "1234\n1234" | passwd ec2-user
--==BOUNDARY==--
