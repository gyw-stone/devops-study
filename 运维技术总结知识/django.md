

安装

```shell
python3 -m venv django # 创建虚拟环境
source django/bin/activate # 激活虚拟环境
pip install django -i https://pypi.doubanio.com/simple
```

创建工程

```shell
django-admin startproject bookmanager # 创建一个名为bookmanager的工程
```

工程总目录与内部文件夹的名称一致

`manage.py` python可执行文件，内置一些python命令

项目内部文件说明

- __init__.py：声明文件
- settings:django的配置文件（数据库、缓存、中间件。。）
- urls：路由文件，访问网站使用的网址
- wsgi：网关系统，被其他计算机访问的文件

```
# 运行创建的网站工程
python manage.py runserver
```

APP

```
- 项目
	- app，用户管理
	- app，订单管理
	- app，后台管理
	- app，API
	...
	
# 创建app
python manage.py startapp app01
# 注册app，工程下的setting文件下INSTALLED_APPS下添加
'app01.apps.App01Config'
# 注册urls
path('index/',admin.site.urls)
```

{% csrf_token %}

```python
import pymysql
# 1.连接mysql
conn = pymysql.connect(host="127.0.0.1", port=3306, user='root', passwd='123456', charset='utf8', db='unicom')

# 2. 发送指令
cursor.execute("insert into admin(username,password,mobile) values('stone', 'qwe123','131982401918')")
conn.commit()

# 3.关闭
cursor.close()
conn.close()
```

```shell
# 安装mysqlclient依赖
apt-get install python3-dev default-libmysqlclient-dev build-essential
pip install mysqlclient
```

创建数据库

`create database EmMa_dj DEFAULT CHARSET utf8 COLLATE utf8_general_ci;`

django操作数据库，orm框架

- 创建、修改、删除数据库中的表【无法创建数据库】
- 操作表中的数据

```
python manage.py makemigrations appname
python manage.py migrate
```

```html
<!DOCTYPE html>
<html lang="en">
<head>
        <meta charset="UTF-8">
        <title>Title</title>
</head>
<body>
<h1>用户列表</h1>
</body>
</html>
~        
```

model操作数据库

```python
# 限定条件搜索
models.PrettyNum.objects.filter(mobile="15884140272",id=12)

data_dict = {"mobile":"15884140272","id":12}
models.PrettyNum.objects.filter(**data_dict)
```

```python
models.PrettyNum.objects.filter(id=12)		# 等于12
models.PrettyNum.objects.filter(id__gt=12)	# 大于12
models.PrettyNum.objects.filter(id__gte=12)	# 大于等于12
models.PrettyNum.objects.filter(id__lt=12)	# 小于12
models.PrettyNum.objects.filter(id__lte=12)	# 小于等于12

data_dict = {"id__lte":12}
models.PrettyNum.objects.filter(**data_dict)

models.PrettyNum.objects.filter(mobile__startswith="1588")	# 以1588开头
models.PrettyNum.objects.filter(mobile__endswith="272")		# 以272结尾
models.PrettyNum.objects.filter(mobile__contains="272")		# 包含272

data_dict = {"mobile__contains":272}
models.PrettyNum.objects.filter(**data_dict)
```

分页

```python
queryset = models.PrettyNum.objects.all()
queryset = models.PrettyNum.objects.all()[0:10]
queryset = models.PrettyNum.objects.filter(id=1)[0:10]
```

```python
data = models.PrettyNum.objects.all().count() # 计算多少条数据
```

