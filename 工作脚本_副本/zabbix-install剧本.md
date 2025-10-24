```yaml
# 依赖没问题情况下，支持centos7以上以及ubuntu
---
- name: 检查zabbix状态
  hosts: all
  vars:
    zabbix_agent2_service_name: zabbix-agent
    install_name: zabbix_agentd_installed
  tasks:
    - name: 检查zabbix是否安装Ubuntu
      when: "'Ubuntu' in ansible_distribution"
      command: dpkg -l | grep {{ zabbix_agent2_service_name }} 
      register: {{ install_name }}
      changed_when: false
    - name: 检查zabbix是否安装CentOS
      when: "'CentOS' in ansible_distribution"
      command: rpm -q {{ zabbix_agent2_service_name }}
      register: {{ install_name }}
      changed_when: false
    - name: 下载Zabbix软件包-Ubuntu
      shell: wget -O /tmp/zabbix-agent2.deb http://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix/zabbix-agent2_6.4.0-1%2Bubuntu20.04_amd64.deb
      when: ansible_distribution == 'Ubuntu'
    - name: 下载Zabbix软件包-CentOS
      shell: wget -O /tmp/zabbix-agent2.rpm http://repo.zabbix.com/zabbix/6.4/rhel/7/x86_64/zabbix-agent2-6.4.3-release1.el7.x86_64.rpm
      when: ansible_distribution == 'CentOS'
    - name: 安装zabbix-CentOS
    	shell: rpm -ivh /tmp/zabbix-agent2.rpm 
  		when: ansible_distribution == 'CentOS'
    - name: 安装zabbix-Ubuntu
    	shell: dpkg -i /tmp/zabbix-agent.deb 
    	shell: apt-get install -y -f
    - name: get ip
      shell: "hostname -I | awk '{print $1}'"
      register: host_ip
    - name: 修改Zabbix Agent2配置文件
      lineinfile:
        path: "/etc/zabbix/zabbix_agent2.conf"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      with_items: 
        - { regexp: '^Server=.*',line: 'Server=172.17.20.28' }
        - { regexp: '^ServerActive=.*',line: 'ServerActive=172.16.200.199' }
        - { regexp: '^Hostname=.*',line: 'Hostname={{ host_ip.stdout }}' }
      when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'CentOS'
    - name: 开机自启设置
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        enabled: yes
      when: not zabbix_agent2_installed.stdout
    - name: 启动服务
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        state: started
      when: not zabbix_agent2_installed.stdout
    - name: 检查服务是否running
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        state: started
        enabled: true
      register: zabbix_agent2_running
      until: zabbix_agent2_running is succeeded
      retries: 10
      delay: 5

```

```yaml
# centos6版本
# 依赖没问题情况下，支持centos7以上以及ubuntu
---
- name: 检查zabbix状态
  hosts: all
  vars:
    zabbix_agent2_service_name: zabbix-agent2
    install_name: zabbix_agent2_installed
  tasks:
    - name: 检查zabbix是否安装CentOS
      when: "'CentOS' in ansible_distribution"
      command: rpm -q {{ zabbix_agent2_service_name }}
      register: {{ install_name }}
      changed_when: false
    - name: 下载软件包和依赖pcre
      yum: 
        name: 
         - zabbix
         - pcre2-10.23-2.el7.x86_64
    - name: get ip
      shell: "hostname -I | awk '{print $1}'"
      register: host_ip
    - name: 修改配置文件
      lineinfile:
        path: "/etc/zabbix/zabbix_agentd.conf"
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      with_items: 
        - { regexp: '^Server=.*',line: 'Server=172.17.20.28' }
        - { regexp: '^ServerActive=.*',line: 'ServerActive=172.16.200.199' }
        - { regexp: '^Hostname=.*',line: 'Hostname={{ host_ip.stdout }}' }
      when: ansible_distribution == 'Ubuntu' or ansible_distribution == 'CentOS'
    - name: 开机自启设置
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        enabled: yes
      when: not zabbix_agentd_installed.stdout
    - name: 启动服务
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        state: started
      when: not zabbix_agentd_installed.stdout
    - name: 检查服务是否running
      systemd:
        name: "{{ zabbix_agent2_service_name }}"
        state: started
        enabled: true
      register: zabbix_agentd_running
      until: zabbix_agentd_running is succeeded
      retries: 10
      delay: 5

```

```yaml
# Ubuntu zabbix-agent
---
- hosts: pong
  tasks:
    - name: 下载deb文件
      shell:  wget -O /tmp/zabbix-agent2.deb http://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix/zabbix-agentd_6.4.0-1%2Bubuntu18.04_amd64.deb
      when: ansible_distribution == 'Ubuntu'
    - name: 安装agent2
      shell:  dpkg -i /tmp/zabbix-agentd.deb
    - name: 更新依赖
      shell: apt-get install -y -f
    - name: get ip
      shell: "hostname -I | awk '{print $1}'"
      register: host_ip
    - name: 替换配置文件
     lineinfile: 
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      with_items: 
        - { regexp: '^Server=.*',line: 'Server=172.17.20.28' }
        - { regexp: '^ServerActive=.*',line: 'ServerAvtive=172.16.200.199' }
        - { regexp: '^Hostname=.*',line: 'Hostname={{ host_ip.stdout }}' }
     - name: 开机自启设置
      systemd:
        name: zabbix-agent
        enabled: yes
      when: not zabbix_agent_installed.stdout
    - name: 启动zabbix
      systemd: 
        name: zabbix-agent
        state: started
```

