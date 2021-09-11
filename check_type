# 判断Linux shell 数据类型
# MAINTAINRT: stone <1614528231@qq.com>
#! /bin/bash
a=`uname -r |awk -F. '{print $1"." $2}'`
echo $a


function check(){
        local b="$1"
        printf "%d" "b" &>/dev/null && echo "integer" && return
        printf "%d" "$(echo $a|sed 's/^[+-]\?0\+//')" &>/dev/null && echo "integer" && return
        printf "f" "$a" &>/dev/null && echo "number" && return
        [ ${#a} -eq 1 ] && echo "char" && return
        echo "string"
}

echo "$a is" $(check "$a")

