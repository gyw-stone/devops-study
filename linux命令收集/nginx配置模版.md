 	## 七层
 	server {
 	   listen 80;
 	   server_name idps.datagrand.com;
 	   return 301 https://$server_name$request_uri;
 	}
 	server {
 	    server_name idps.datagrand.com;
 	    listen 443 ssl;
 	    # 选择需要的证书
 	    ssl_certificate /etc/nginx/ssl/datagrand.com.pem;
 	    ssl_certificate_key  /etc/nginx/ssl/datagrand.com.key;
 	    #ssl_certificate /etc/nginx/ssl/ssl_cn/datagrand.cn.pem;
 	    #ssl_certificate_key /etc/nginx/ssl/ssl_cn/datagrand.cn.key;
 	    # stop 3DES
 	    ssl_ecdh_curve secp384r1:prime256v1;
 	    # 加密算法
 	    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
 	    add_header X-Frame-Options SAMEORIGIN;
 	    ssl_protocols TLSv1.2 TLSv1.3;
 	    ssl_prefer_server_ciphers on;
 	    client_max_body_size 5000M;
 	    proxy_connect_timeout 1200;
 	    keepalive_timeout 1200;
 	    proxy_read_timeout 1200;
 	    proxy_send_timeout 1200;
 	    location / {
 	        proxy_connect_timeout 1200;
 	        keepalive_timeout 1200;
 	        proxy_read_timeout 1200;
 	        proxy_send_timeout 1200;
 	        client_max_body_size 5000M;
 	        proxy_set_header  Host $host;
 	        proxy_set_header  X-Real-IP $remote_addr;
 	        proxy_set_header  X-Forwarded-Proto https;
 	        proxy_set_header  X-Forwarded-For $remote_addr;
 	        proxy_set_header  X-Forwarded-Host $remote_addr;
 	        proxy_pass http://idps.datagrand.com/; # 修改这里
 	        proxy_redirect off;
 	        # 解决跨域问题
 	        add_header 'Access-Control-Allow-Origin' '*' always;
 	        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
 	        add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Requested-With,If-Modified-Since' always;
 	        # 支持 CORS 预检请求
 	        if ($request_method = OPTIONS ) {
 	           add_header 'Access-Control-Allow-Origin' '*';
 	           add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
 	           add_header 'Access-Control-Allow-Headers' 'Authorization,Content-Type,Accept,Origin,User-Agent,DNT,Cache-Control,X-Requested-With,If-Modified-Since';
 	           add_header 'Access-Control-Max-Age' 1728000;
 	           add_header 'Content-Type' 'text/plain charset=UTF-8';
 	           add_header 'Content-Length' 0;
 	           return 204;
 	       } 
 	       # ws协议
 	       #proxy_set_header Upgrade $http_upgrade; 
 	       #proxy_set_header Connection "Upgrade";
 	
 	    }
 	}

```
# 四层
upstream  name {
  server IP:PORT weight=5 max_fails=3 fail_timeout=30s;

}
server {
    listen PORT;
    proxy_pass name;
    proxy_timeout 300s;
    proxy_connect_timeout 5s;
}
```





