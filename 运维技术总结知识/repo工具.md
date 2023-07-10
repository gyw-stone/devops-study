### repo工具

**1. 是什么**

Repo是基于git的仓库管理工具，是一个python脚本，用来管理多git仓库，可以做统一的上传等其他操作，并且可以自动化部分Android开发流程

**2. default.xml详解**

```
#Manifest元素详解
最顶层的XML元素。
​
#remote元素
设置远程git服务器的属性，包括下面的属性：
​
name: 远程git服务器的名字，直接用于git fetch, git remote 等操作
alias: 远程git服务器的别名，如果指定了，则会覆盖name的设定。在一个manifest中， name不能重名，但alias可以重名。
fetch: 所有projects的git URL 前缀
review: 指定Gerrit的服务器名，用于repo upload操作。如果没有指定，则repo upload没有效果。
一个manifest文件中可以配置多个remote元素，用于配置不同的project默认下载指向。
​
#default元素
设定所有projects的默认属性值，如果在project元素里没有指定一个属性，则使用default元素的属性值。
​
remote: 之前定义的某一个remote元素中name属性值，用于指定使用哪一个远程git服务器。
revision: git分支的名字，例如master或者refs/heads/master
sync_j: 在repo sync中默认并行的数目。
sync_c: 如果设置为true，则只同步指定的分支(revision 属性指定)，而不是所有的ref内容。
sync_s: 如果设置为true，则会同步git的子项目
Example:
    <default remote="main" revision="platform/main"/>
  
​
#project元素
指定一个需要clone的git仓库。
​
name: 唯一的名字标识project，同时也用于生成git仓库的URL。格式如下：
      ${remote_fetch}/${project_name}.git
path: 可选的路径。指定git clone出来的代码存放在本地的子目录。如果没有指定，则以name作为子目录名。
remote: 指定之前在某个remote元素中的name。
revision: 指定需要获取的git提交点，可以是master, refs/heads/master, tag或者SHA-1值。如果不设置的话，默认下载当前project，当前分支上的最新代码。
groups: 列出project所属的组，以空格或者逗号分隔多个组名。所有的project都自动属于"all"组。每一个project自动属于name:'name' 和path:'path'组。
例如<project name="monkeys" path="barrel-of"/>，它自动属于default, name:monkeys, and path:barrel-of组。如果一个project属于notdefault组，则，repo sync时不会下载。
sync_c: 如果设置为true，则只同步指定的分支(revision 属性指定)，而不是所有的ref内容。
sync_s: 如果设置为true，则会同步git的子项目。
upstream: 在哪个git分支可以找到一个SHA1。用于同步revision锁定的manifest(-c 模式)。该模式可以避免同步整个ref空间。
annotation: 可以有多个annotation，格式为name-value pair。在repo forall 命令中这些值会导入到环境变量中。
remove-project: 从内部的manifest表中删除指定的project。经常用于本地的manifest文件，用户可以替换一个project的定义。
子元素
​
#Include元素
通过name属性可以引入另外一个manifest文件(路径相对与manifest repository's root)。
```

```xml
# 简单例子
<?xml version="1.0" encoding="UTF-8" ?>
<manifest>
    <remote fetch="https://gitee.com/openharmony/" name="origin" review="https://openharmony.gitee.com/openharmony/"/>
    <default remote="origin" revision="master" sync-j="4" />
    <project name="graphic_utils" path="foundation/graphic/utils"  />
</manifest>
```

**3. 常用命令**

- repo init：初始化一个新的repo仓库，创建一个manifest.xml文件，并制定使用哪个远程服务器进行同步

- repo sync：同步所有代码

  ```
  repo sync [<project>]
  repo sync platform/build
  ```

- repo start：创建一个新的分支来在当前的仓库中工作

  ```
  repo start  <newbranchname> [--all | <project>…]
  repo start stable --all # 假设清单文件中设定的分支是test1，那么执行以上指令就是对所有项目，在test1的基础上创建特性分支stable
  repo start stable platform/build platform/bionic # 假设清单文件中设定的分支是test1，那么执行以上指令就是对platform/build、platform/bionic项目，在test1的基础上创建特性分支stable
  ```

- repo forall：对所有的仓库执行相同的命令

- repo status：显示当前仓库和子模块的状态

- repo abandon：放弃当前的更改并恢复默认情况

- repo upload：将更改上传到代码审查服务器进行审核

- repo diff：比较当前仓库所使用的清单文件

  ```
  repo diff # 查看所有项目
  repo diff platform/build platform/bion # 只查看其中两个项目
  ```

- repo manifest：生成当前仓库所使用的清单文件

- repo prune：git branch -d 命令的封装，扫描项目的各个分支，并删除已经合并的分支

  ```
  repo prune [<project>]
  ```


### Helm

**简介**

Helm是k8s的包管理器

**使用**

初始化，添加chart仓库

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami # 查看安装的charts列表
```

安装chart

```
helm repo update # 确定拿到最新的charts列表
helm install bitnami/mysql --generate-name # 安装chart
helm show chart bitnami/mysql # 简单查看chart基本信息
helm show all bitnami/mysql # 获取该chart所有信息
```

**Chart 文件结构**

chart是一个组织在文件目录中的集合。目录名称就是chart。比如描述Wordpress的chart可以存储在wordpress/目录中

```
wordpress/
  Chart.yaml          # 包含了chart信息的YAML文件
  LICENSE             # 可选: 包含chart许可证的纯文本文件
  README.md           # 可选: 可读的README文件
  values.yaml         # chart 默认的配置值
  values.schema.json  # 可选: 一个使用JSON结构的values.yaml文件
  charts/             # 包含chart依赖的其他chart
  crds/               # 自定义资源的定义
  templates/          # 模板目录， 当和values 结合时，可生成有效的Kubernetes manifest文件
  templates/NOTES.txt # 可选: 包含简要使用说明的纯文本文件
```

**Chart.yaml文件 **

```yaml
apiVersion: chart API 版本 （必需）
name: chart名称 （必需）
version: 语义化2 版本（必需）
kubeVersion: 兼容Kubernetes版本的语义化版本（可选）
description: 一句话对这个项目的描述（可选）
type: chart类型 （可选）
keywords:
  - 关于项目的一组关键字（可选）
home: 项目home页面的URL （可选）
sources:
  - 项目源码的URL列表（可选）
dependencies: # chart 必要条件列表 （可选）
  - name: chart名称 (nginx)
    version: chart版本 ("1.2.3")
    repository: （可选）仓库URL ("https://example.com/charts") 或别名 ("@repo-name")
    condition: （可选） 解析为布尔值的yaml路径，用于启用/禁用chart (e.g. subchart1.enabled )
    tags: # （可选）
      - 用于一次启用/禁用 一组chart的tag
    import-values: # （可选）
      - ImportValue 保存源值到导入父键的映射。每项可以是字符串或者一对子/父列表项
    alias: （可选） chart中使用的别名。当你要多次添加相同的chart时会很有用
maintainers: # （可选）
  - name: 维护者名字 （每个维护者都需要）
    email: 维护者邮箱 （每个维护者可选）
    url: 维护者URL （每个维护者可选）
icon: 用做icon的SVG或PNG图片URL （可选）
appVersion: 包含的应用版本（可选）。不需要是语义化，建议使用引号
deprecated: 不被推荐的chart （可选，布尔值）
annotations:
  example: 按名称输入的批注列表 （可选）.
```

**helm install 生命周期**

1. 用户执行helm install foo
2. Helm库调用安装API
3. 在一些验证之后，库会渲染foo模板
4. 库会加载结果资源到Kubernetes
5. 库会返回发布对象给客户端
6. 客户端退出

**helm install 周期定义了两个钩子并全部执行，例如：pre-install`和`post-install**

1. 用户返回 helm install foo
2. Helm库调用安装API
3. 在 crds/ 目录中的CRD会被安装
4. 在一些验证之后，库会渲染foo模板
5. 库准备执行pre-install 钩子(将hook资源加载到k8s中)
6. 库按照权重对钩子排序(默认将权重指定为0)，然后在资源种类排序，最后按名称正序排列
7. 库先加载最小权重的钩子
8. 库会等到钩子是"Ready"状态(CRD除外)
9. 库将生成的资源加载到Kubernetes中
10. 库执行post-install 钩子
11. 库会等到钩子 "Ready"
12. 库会返回发布对象(和其他数据)给客户端
13. 客户端退出

**helm 一般操作**

```
helm search:   搜索chart
helm pull:    下载chart到本地目录查看
helm install:   上传chart到Kubernetes
helm list:     列出已发布的chart
helm completion - 为指定的shell生成自动补全脚本
helm create - 使用给定的名称创建chart
helm dependency - 管理chart依赖
helm env - helm客户端环境信息
helm get - 下载命名版本的扩展信息
helm history - 检索发布历史
helm install - 安装chart
helm lint - 验证chart是否存在问题
helm list - 列举发布版本
helm package - 将chart目录打包
helm plugin - 安装、列举或卸载Helm插件
helm pull - 从仓库下载chart并（可选）在本地目录中打开
helm push - 推送chart到远程
helm registry - 从注册表登录或登出
helm repo - 添加、列出、删除、更新和索引chart仓库
helm rollback - 回滚发布到上一个版本
helm search - helm中搜索关键字
helm show - 显示chart信息
helm status - 显示命名版本的状态
helm template - 本地渲染模板
helm test - 执行发布的测试
helm uninstall - 卸载版本
helm upgrade - 升级版本
helm verify - 验证给定路径的chart已经被签名且是合法的
helm version - 打印客户端版本信息
```

