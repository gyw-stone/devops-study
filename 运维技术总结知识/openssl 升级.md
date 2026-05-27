```
yum install -y gcc make
# 没有下面这包会导致 config 失败
yum install -y perl-IPC-Cmd perl-Data-Dump zlib-devel perl-Digest-SHA perl-Data-Dumper
# 如果config时 enable-fips,那还需要下面，否则make编译会失败
# yum install -y perl-Digest-SHA

 cd openssl-3.3.1
./config enable-fips --prefix=/usr/local --openssldir=/usr/local/openssl
#./config --prefix=/usr/local --openssldir=/usr/local/openssl
make -j 8 && make install 
mv /usr/bin/openssl /usr/bin/openssl.1.0.2k_bak
# mv /usr/include/openssl /usr/include/openssl_bak
ln -s /usr/local/bin/openssl /usr/bin/openssl
ln -snf /usr/local/include/openssl /usr/include/openssl
cd /usr/local/lib64
cp libssl.so.3 /usr/lib/libssl.so.3
cp libcrypto.so.3 /usr/lib/libcrypto.so.3
cp libcrypto.so.3 /usr/lib64/libcrypto.so.3
# ln -nfs /usr/local/openssl/lib/libssl.so.3 /usr/lib64/libssl.so
# ln -nfs /usr/local/openssl/lib/libcrypto.so.3 /usr/lib64/libcrypto.so

echo "/usr/local/lib64" >> /etc/ld.so.conf  
ldconfig -v
openssl version
#old 
/usr/lib64/libssl.so -> libssl.so.1.0.2k
/usr/lib64/libcrypto.so -> libcrypto.so.1.0.2k
```







