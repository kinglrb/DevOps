# ----------------------------------#添加yum源
#需要安装工具支持
# yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install vim -y
rpm -qa |grep ssh

yum -y install wget
wget -v
# ----------------------------------安装依赖------------------
# 保证Gitlab可用运行内存大于4G，端口未被占用.
# 赋予权限：
chmod -R 755 /var/log/gitlab
#在安装Postfix期间，可能会出现配置屏幕。选择“Internet Site”并按enter键。使用您的服务器的外部DNS以“mail name”并按enter。如果出现额外的屏幕，继续按enter键接受默认值
yum install -y curl openssh-server openssh-clients cronie policycoreutils-python postfix
sudo systemctl enable sshd
sudo systemctl start sshd
yum install firewalld systemd -y
systemctl status firewalld
service firewalld  start
# 添加http服务到firewalld,pemmanent表示永久生效，若不加--permanent系统下次启动后失效
sudo firewall-cmd --permanent --add-service=http
sudo systemctl reload firewalld
vim /etc/postfix/main.cf
	inet_interfaces = localhost改为inet_interfaces = all
sudo systemctl enable postfix
sudo systemctl start postfix

# ------------------------------------------安装gitlab
# -------------------------------A方案：rpm离线安装
# 添加gitlab镜像.EL是Red Hat Enterprise Linux的简写
wget https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7/gitlab-ce-10.0.0-ce.0.el7.x86_64.rpm
rpm -ivh gitlab-ce-10.0.0-ce.0.el7.x86_64.rpm

# 修改gitlab配置文件（gitlab.yml 和 gitlab.rb）
# 修改gitlab.yml
# 将localhost改为自定义域名
vim /var/(rpm安装位置)/gitlab/gitlab-rails/etc/gitlab.yml
	# 更改localhost为gitlab服务器的ip 或者 自定义域名,
# 指定服务器ip和自定义端口(默认8080端口).
vim  /etc/gitlab/gitlab.rb
   external_url http://IP:8080
   
# 防火墙开放相对应端口
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
# 查看已开放端口：
firewall-cmd --list-ports

# 重置并启动GitLab
gitlab-ctl reconfigure
gitlab-ctl restart
gitlab-ctl status
# 个人电脑(客户端)修改host（gitlab服务器地址）
# 访问GitLab页，如果没有域名，输入服务器ip和指定端口访问，初始账户: root 密码:

# 软件已安装
# 查看与rpm包相关的文件和其他信息   
rpm -qa | grep 包名
# 查询包是否被安装：
rpm -q 包名
# 删除软件包：
rpm -e 包名
