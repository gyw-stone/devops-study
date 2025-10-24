```
systemctl disable firewalld 
systemctl stop firewalld

mkdir /etc/docker
yum install -y vim telnet curl wget ncdu net-tools iftop lsof tcpdump bash-completion htop 


 yum install -y yum-utils device-mapper-persistent-data lvm2 >/dev/null
 yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo >/dev/null
 yum install -y docker-ce-20.10.24 docker-ce-cli-20.10.24  docker-ce-rootless-extras-20.10.24  >/dev/null 

echo '{
"registry-mirrors": ["https://4p5gxeik.mirror.aliyuncs.com"],
"exec-opts": ["native.cgroupdriver=systemd"],
"storage-driver": "overlay2",
"storage-opts":["overlay2.override_kernel_check=true"],
"log-driver": "json-file",
"log-opts": {
        "max-size": "500m",
        "max-file": "3"
},
"oom-score-adjust": -1000,
"bip": "172.20.0.1/16",
"fixed-cidr": "172.20.0.0/24",
"metrics-addr" : "0.0.0.0:9323",
"experimental" : true,
"default-address-pools": [
{"base": "10.252.0.0/24", "size": 24},
{"base": "10.252.1.0/24", "size": 24},
{"base": "10.252.2.0/24", "size": 24}]
}' | tee /etc/docker/daemon.json > /dev/null
systemctl enable docker
systemctl daemon-reload
systemctl start docker


echo '
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
kernel.sem=500 64000 64 256
##打开文件数参数(20*1024*1024)
fs.file-max= 20971520
##WEB Server参数
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=1200
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_rmem=4096 87380 8388608
net.ipv4.tcp_wmem=4096 87380 8388608
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_tw_recycle=1
net.ipv4.tcp_fin_timeout=30
##TCP补充参数
net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
##禁用ipv6
net.ipv6.conf.all.disable_ipv6 =1
net.ipv6.conf.default.disable_ipv6 =1
##swap使用率优化
vm.swappiness=0' | tee /etc/sysctl.conf > /dev/null

sysctl -p

```

```
---
- name: Setup Docker and System Configuration
  hosts: all
  become: true
  tasks:

    # Disable and stop firewalld service
    - name: Disable and stop firewalld service on CentOS
      systemd:
        name: firewalld
        state: stopped
        enabled: no
      when: ansible_facts['distribution'] == 'CentOS'

    # Create /etc/docker directory if it does not exist
    - name: Create /etc/docker directory if not exists
      file:
        path: /etc/docker
        state: directory
        mode: '0755'

    # Install necessary tools based on system
    - name: Install necessary tools for CentOS
      yum:
        name:
          - vim
          - telnet
          - curl
          - wget
          - ncdu
          - net-tools
          - iftop
          - lsof
          - tcpdump
          - bash-completion
        state: present
      when: ansible_facts['distribution'] == 'CentOS'

    - name: Install necessary tools for Ubuntu
      apt:
        name:
          - vim
          - telnet
          - curl
          - wget
          - ncdu
          - net-tools
          - iftop
          - lsof
          - tcpdump
          - bash-completion
        state: present
        update_cache: yes
      when: ansible_facts['distribution'] == 'Ubuntu'

    # Install Docker dependencies for CentOS
    - name: Install Docker dependencies for CentOS
      yum:
        name:
          - yum-utils
          - device-mapper-persistent-data
          - lvm2
        state: present
      when: ansible_facts['distribution'] == 'CentOS'

    # Install Docker dependencies for Ubuntu
    - name: Install Docker dependencies for Ubuntu
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present
      when: ansible_facts['distribution'] == 'Ubuntu'

    # Add Docker repository for CentOS
    - name: Add Docker repository for CentOS
      command: yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
      when: ansible_facts['distribution'] == 'CentOS'

    # Add Docker repository for Ubuntu
    - name: Add Docker repository for Ubuntu
      apt_key:
        url: https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg
        state: present
      when: ansible_facts['distribution'] == 'Ubuntu'
    
    - name: Add Docker APT repository for Ubuntu
      apt_repository:
        repo: 'deb https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable'
        state: present
      when: ansible_facts['distribution'] == 'Ubuntu'

    # Install Docker on CentOS
    - name: Install Docker on CentOS
      yum:
        name:
          - docker-ce-20.10.24
          - docker-ce-cli-20.10.24
          - docker-ce-rootless-extras-20.10.24
        state: present
      when: ansible_facts['distribution'] == 'CentOS'

    # Install Docker on Ubuntu
    - name: Install Docker on Ubuntu
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
        state: present
      when: ansible_facts['distribution'] == 'Ubuntu'

    # Configure Docker daemon
    - name: Configure Docker daemon
      copy:
        dest: /etc/docker/daemon.json
        content: |
          {
            "registry-mirrors": ["https://4p5gxeik.mirror.aliyuncs.com"],
            "exec-opts": ["native.cgroupdriver=systemd"],
            "storage-driver": "overlay2",
            "storage-opts":["overlay2.override_kernel_check=true"],
            "log-driver": "json-file",
            "log-opts": {
              "max-size": "500m",
              "max-file": "3"
            },
            "oom-score-adjust": -1000,
            "bip": "172.20.0.1/16",
            "fixed-cidr": "172.20.0.0/24",
            "metrics-addr" : "0.0.0.0:9323",
            "experimental" : true,
            "default-address-pools": [
              {"base": "10.252.0.0/24", "size": 24},
              {"base": "10.252.1.0/24", "size": 24},
              {"base": "10.252.2.0/24", "size": 24}
            ]
          }
      notify:
        - Restart Docker

    # Enable Docker service and start it
    - name: Enable Docker service and start it
      systemd:
        name: docker
        state: started
        enabled: yes

    - name: Reload systemd to apply Docker changes
      systemd:
        daemon_reload: yes

    # Configure sysctl settings
    - name: Configure sysctl settings
      copy:
        dest: /etc/sysctl.conf
        content: |
          kernel.sysrq = 0
          kernel.core_uses_pid = 1
          kernel.msgmnb = 65536
          kernel.msgmax = 65536
          kernel.shmmax = 68719476736
          kernel.shmall = 4294967296
          kernel.sem=500 64000 64 256
          fs.file-max= 20971520
          net.ipv4.tcp_tw_reuse=1
          net.ipv4.tcp_tw_recycle=1
          net.ipv4.tcp_fin_timeout=30
          net.ipv4.tcp_keepalive_time=1200
          net.ipv4.ip_local_port_range = 1024 65535
          net.ipv4.tcp_rmem=4096 87380 8388608
          net.ipv4.tcp_wmem=4096 87380 8388608
          net.ipv4.tcp_max_syn_backlog=8192
          net.ipv4.tcp_max_tw_buckets = 5000
          net.ipv4.ip_forward = 1
          net.ipv4.conf.default.rp_filter = 1
          net.ipv4.conf.default.accept_source_route = 0
          net.ipv4.tcp_syncookies = 1
          net.ipv4.tcp_sack = 1
          net.ipv4.tcp_window_scaling = 1
          net.core.wmem_default = 8388608
          net.core.rmem_default = 8388608
          net.core.rmem_max = 16777216
          net.core.wmem_max = 16777216
          net.core.netdev_max_backlog = 262144
          net.core.somaxconn = 65535
          net.ipv4.tcp_max_orphans = 3276800
          net.ipv4.tcp_timestamps = 0
          net.ipv4.tcp_synack_retries = 1
          net.ipv4.tcp_syn_retries = 1
          net.ipv4.tcp_mem = 94500000 915000000 927000000
          net.ipv6.conf.all.disable_ipv6 =1
          net.ipv6.conf.default.disable_ipv6 =1
          vm.swappiness=0
      notify:
        - Apply sysctl changes

    - name: Apply sysctl changes
      command: sysctl -p

  handlers:
    - name: Restart Docker
      systemd:
        name: docker
        state: restarted

    - name: Apply sysctl changes
      command: sysctl -p

```





