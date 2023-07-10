## Go

### go内置函数

| 函数名            | 作用                            |
| ----------------- | ------------------------------- |
| close             | 管道关闭                        |
| len,cap           | 返回数组、切片、Map的长度或容量 |
| new,make          | 内存分配                        |
| copy,append       | 操作切片                        |
| panic,recover     | 错误处理                        |
| print,pringln     | 打印                            |
| complex,real,imag | 操作复数                        |

作用域： {} 



defer: golang内置函数，在函数运行结束时执行

ps： defer定义的函数，关注在最后一层函数体



**单元测试的关键组成部分**

预备案例

预期结果

组件调用

衡量预期
