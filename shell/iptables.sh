################
author: stone  #
################
#!/bin/bash
set -e

## nat cidr
cidr=10.8.0.0/24
## dev
ipv4Cidr=10.8.0.0/25
## op
op_ipset=10.8.0.128/26
## ops,运维
ops_ipset=10.8.0.192/26
device=eth0
port=51820
resolve_domain() {
  nslookup "$1" 2>/dev/null \
    | awk '/^Address: / { print $2 }' \
    | grep -E '^[0-9.]+$' || true
}


drop(){ 
  iptables -F
  iptables -t nat -F
}
add(){
  iptables -t nat -A POSTROUTING -s ${cidr} -d 172.17.0.0/16 -o ${device} -j MASQUERADE;
  iptables -A INPUT -p udp --dport ${port} -j ACCEPT;
  iptables -A INPUT -i wg0 -j ACCEPT;
  iptables -P FORWARD DROP;
  iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  for ip in $(resolve_domain test.com); do
    iptables -A FORWARD -i wg0 -s ${ipv4Cidr} -d "$ip" -j ACCEPT;
    iptables -A FORWARD -i wg0 -s ${op_ipset} -d "$ip" -j ACCEPT;
    iptables -A FORWARD -i wg0 -s ${ops_ipset} -d "$ip" -j ACCEPT;
  done
  iptables -A FORWARD -i wg0 -s ${ops_ipset} -d 172.17.128.70 -j ACCEPT;
}

main(){
  IP=$(hostname -i | awk -F ' '  '{print $1}')
  if [[ $IP != 172.17.* ]]; then
      drop
      add
  fi    
}

main

