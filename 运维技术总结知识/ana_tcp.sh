#!/bin/bash
# complete_tcp_decode.sh

echo "完整 TCP 连接解码"
echo "=================="

awk '
function hex2dec(hex) {
    cmd = "echo \"ibase=16; " toupper(hex) "\" | bc"
    cmd | getline result
    close(cmd)
    return result
}

function hex2ip(hex) {
    if (length(hex) == 8) {
        p1 = hex2dec(substr(hex, 7, 2))
        p2 = hex2dec(substr(hex, 5, 2)) 
        p3 = hex2dec(substr(hex, 3, 2))
        p4 = hex2dec(substr(hex, 1, 2))
        return p1 "." p2 "." p3 "." p4
    }
    return "IPv6"
}

NR>1 {
    split($2, local, ":")
    split($4, remote, ":")
    
    local_ip = hex2ip(local[1])
    
    local_port = hex2dec(local[2])
    remote_ip = hex2ip(remote[1])
    remote_port = hex2dec(remote[2])
    
    print "连接 " NR-1 ":"
    print "  本地: " local_ip ":" local_port
    print "  远程: " remote_ip ":" remote_port
    print "  状态: ESTABLISHED"
    print "---"
}' tcp
