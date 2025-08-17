# 中国网络环境安装指南

## 🇨🇳 专为中国用户优化

本指南专门针对中国大陆网络环境进行了优化，解决网络访问限制和速度问题。

## 🚀 快速安装

### 方法1: 一键安装（推荐）

```bash
# 下载并运行安装脚本
curl -fsSL https://gitee.com/your-repo/tools/raw/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh clash
```

### 方法2: 克隆仓库安装

```bash
# 使用Gitee镜像（国内更快）
git clone https://gitee.com/your-repo/tools.git
cd tools
sudo bash install.sh clash
```

## 🌐 网络环境优化特性

### 1. 多重下载源
脚本自动尝试以下国内镜像源：
- **ghproxy.com** - GitHub代理加速
- **mirror.ghproxy.com** - 备用代理
- **github.91chi.fun** - 91代理
- **hub.fastgit.xyz** - FastGit镜像
- **download.fastgit.org** - FastGit下载镜像

### 2. DNS优化配置
- **阿里DNS**: 223.5.5.5, 223.6.6.6
- **腾讯DNS**: 119.29.29.29
- **114DNS**: 114.114.114.114
- **DoH支持**: 阿里、腾讯、360等国内DoH服务

### 3. 智能分流规则
- 自动识别国内外网站
- 国内网站直连，不消耗代理流量
- 包含主流国内服务（淘宝、微信、抖音等）

## 📋 安装前准备

### 1. 检查网络连接
```bash
# 测试基本网络连接
ping -c 3 223.5.5.5

# 测试GitHub访问（可能较慢或失败，正常）
curl -I https://github.com --connect-timeout 10
```

### 2. 系统要求
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+
- 需要root权限
- 至少1GB可用空间

## 🔧 安装步骤详解

### 步骤1: 下载安装脚本
```bash
# 如果GitHub访问困难，使用以下命令：
# 方法A: 使用代理下载
curl -x socks5://your-proxy:port -fsSL https://raw.githubusercontent.com/your-repo/tools/main/install.sh -o install.sh

# 方法B: 使用国内Gitee镜像
wget https://gitee.com/your-repo/tools/raw/main/install.sh

# 方法C: 手动下载后上传到服务器
# 将文件上传到服务器后：
chmod +x install.sh
```

### 步骤2: 运行安装
```bash
# 运行安装脚本
sudo ./install.sh clash

# 如果下载失败，脚本会提供手动安装指导
```

### 步骤3: 配置订阅
```bash
# 编辑配置文件
sudo nano /etc/clash/config.yaml

# 或复制优化的示例配置
sudo cp /opt/clash/example-config.yaml /etc/clash/config.yaml
sudo nano /etc/clash/config.yaml
```

在配置文件中找到并修改订阅链接：
```yaml
proxy-providers:
  main-subscription:
    type: http
    url: "your-subscription-url-here"  # 替换为您的订阅链接
    interval: 86400
    path: ./proxies/main.yaml
```

### 步骤4: 启动服务
```bash
# 启动Clash服务
clash-ctl start

# 检查服务状态
clash-ctl status

# 查看启动日志
clash-ctl logs
```

## ⚡ 代理模式选择

### 1. 系统代理模式（适合开发）
```bash
# 启用系统代理
clash-ctl proxy-enable

# 测试代理
curl http://google.com
export http_proxy=http://127.0.0.1:7890
curl http://ip-api.com/json
```

### 2. TUN透明代理模式（推荐）
```bash
# 启用TUN模式
clash-ctl tun-enable

# 测试连接
curl http://google.com
curl http://ip-api.com/json
```

## 🌍 网络连接测试

### 基础连接测试
```bash
# 测试本地代理端口
curl -I http://127.0.0.1:7890

# 测试SOCKS5代理
curl --socks5 127.0.0.1:7891 http://google.com

# 测试透明代理
curl http://google.com
```

### 速度测试
```bash
# 国内网站速度测试（应该很快）
time curl -o /dev/null -s http://www.baidu.com

# 国外网站速度测试（通过代理）
time curl -o /dev/null -s http://www.google.com

# 下载速度测试
wget --spider http://speed.neu.edu.cn/100MB.zip
```

## 🛠️ 常见问题解决

### 1. 下载失败问题
```bash
# 如果所有下载源都失败，手动下载
# 1. 在有代理的环境下载clash二进制文件
# 2. 上传到服务器 /tmp/ 目录
# 3. 重新运行安装脚本

# 或者使用备用安装方法
cd /tmp
wget https://github.com/Dreamacro/clash/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz
sudo mv clash-linux-amd64-v1.18.0.gz /opt/clash/
cd /opt/clash
sudo gunzip clash-linux-amd64-v1.18.0.gz
sudo mv clash-linux-amd64-v1.18.0 clash
sudo chmod +x clash
```

### 2. DNS解析问题
```bash
# 如果DNS解析有问题，临时使用系统DNS
sudo systemctl stop systemd-resolved
echo "nameserver 223.5.5.5" | sudo tee /etc/resolv.conf

# 重启Clash服务
clash-ctl restart
```

### 3. 代理连接问题
```bash
# 检查防火墙设置
sudo ufw status
sudo iptables -L

# 确保端口未被占用
sudo netstat -tlnp | grep :7890
sudo ss -tlnp | grep :7890

# 检查Clash进程
ps aux | grep clash
```

### 4. 订阅更新问题
```bash
# 手动更新订阅
curl -o /tmp/subscription.yaml "your-subscription-url"
sudo mv /tmp/subscription.yaml /etc/clash/proxies/

# 重载配置
clash-ctl reload
```

## 🔐 安全建议

### 1. 保护订阅链接
- 不要在公共场所分享订阅链接
- 定期更换订阅密码
- 使用HTTPS订阅链接

### 2. 系统安全
```bash
# 设置防火墙规则
sudo ufw allow 22/tcp
sudo ufw allow from 127.0.0.1
sudo ufw --force enable

# 定期更新系统
sudo apt update && sudo apt upgrade
```

### 3. 日志管理
```bash
# 定期清理日志
sudo journalctl --vacuum-time=7d
sudo find /var/log -name "*.log" -mtime +7 -delete
```

## ⚙️ 高级配置

### 1. 自定义规则
编辑 `/etc/clash/config.yaml`，添加自定义规则：
```yaml
rules:
  # 公司内网直连
  - IP-CIDR,192.168.0.0/16,🎯 全球直连
  - IP-CIDR,10.0.0.0/8,🎯 全球直连
  
  # 特定域名代理
  - DOMAIN-SUFFIX,company.com,🚀 代理选择
  
  # 开发相关
  - DOMAIN-SUFFIX,stackoverflow.com,🚀 代理选择
  - DOMAIN-SUFFIX,github.com,🚀 代理选择
```

### 2. 性能优化
```yaml
# 在config.yaml中调整
tun:
  stack: system  # 或 gvisor，根据性能测试选择
  
dns:
  enable: true
  enhanced-mode: fake-ip  # 提高解析速度
  
# 调整日志级别
log-level: warning  # 减少I/O开销
```

### 3. 开机自启优化
```bash
# 确保服务开机自启
sudo systemctl enable clash

# 设置网络依赖
sudo systemctl edit clash
# 添加以下内容：
[Unit]
After=network-online.target
Wants=network-online.target
```

## 📱 Web管理面板

### 1. 访问面板
- **本地API**: http://127.0.0.1:9090
- **推荐面板**: http://clash.razord.top
- **备用面板**: http://yacd.haishan.me

### 2. 安全设置
编辑配置文件设置密码：
```yaml
external-controller: 127.0.0.1:9090
secret: "your-secret-password"
```

## 📈 性能监控

### 1. 连接监控
```bash
# 实时查看连接
clash-ctl logs | grep -E "(error|fail|timeout)"

# 监控网络流量
sudo nethogs
sudo iftop
```

### 2. 系统资源
```bash
# 查看Clash资源使用
top -p $(pgrep clash)
ps aux | grep clash
```

## 🔄 维护和更新

### 1. 定期维护
```bash
# 创建维护脚本
cat > /usr/local/bin/clash-maintenance << 'EOF'
#!/bin/bash
# 清理日志
journalctl --vacuum-time=7d
# 重启服务
systemctl restart clash
# 测试连接
curl -s http://google.com > /dev/null && echo "Clash运行正常" || echo "Clash连接异常"
EOF

chmod +x /usr/local/bin/clash-maintenance

# 设置定期执行
echo "0 3 * * 0 /usr/local/bin/clash-maintenance" | sudo crontab -
```

### 2. 备份配置
```bash
# 备份配置文件
sudo tar -czf /root/clash-backup-$(date +%Y%m%d).tar.gz /etc/clash /opt/clash
```

这样，您就拥有了一个完全针对中国网络环境优化的Clash代理服务！🚀
