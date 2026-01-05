## 背景：自建根证书，根据根证书制作绑定的域名证书，上传alb，让alb做mtls验证，已有rootCA.crt rootCA.key
1.创建证书配置文件
vim server_cert.conf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C = CN
ST = HongKong
L = HongKong
OU = Dev
CN = mtls.yourdomain.com  # 主要域名

[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth
subjectAltName = @alt_names  # 关键：添加SAN扩展

[alt_names]
DNS.1 = mtls.yourdomain.com      # 主域名
DNS.2 = *.mtls.yourdomain.com    # 通配符子域名

2.生成服务器证书
# 生成服务器私钥
openssl genrsa -out server.key 2048

# 生成证书签名请求（CSR）
openssl req -new -key server.key -out server.csr -config server_cert.conf

# 使用你的根CA签发证书（关键步骤）
openssl x509 -req -in server.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -out server.crt -days 365 \
  -extfile server_cert.conf -extensions v3_req

# 验证证书中的域名信息
openssl x509 -in server.crt -text -noout | grep -A 1 "Subject Alternative Name"

3.创建证书链
# 合并服务器证书和CA证书
cat server.crt rootCA.crt > server_chain.crt
# 验证
openssl verify -CAfile rootCA.crt server_chain.crt
# 应该输出: server_chain.crt: OK

4.AWS ACM创建证书，传入server.crt server.key 以及 server_chain.crt

5.上传根CA到S3
使用的S3创建一个文件，比如mtls，然后上传根CA到S3，也就是rootCA.crt

6.配置ALB mtls
绑定对应的sn证书，替换默认证书为导入证书，开启mtls认证，然后选择S3
