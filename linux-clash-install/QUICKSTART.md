# Clash 快速开始指南

## 一键安装

### 方法1: 使用主安装脚本

```bash
# 克隆仓库
git clone <your-repo-url> tools
cd tools

# 安装 Clash
sudo bash install.sh clash
```

### 方法2: 直接运行 Clash 安装脚本

```bash
cd tools/linux-clash-install
sudo bash clash-install.sh
```

## 配置订阅

安装完成后，需要配置您的代理订阅：

```bash
# 编辑配置文件
sudo nano /etc/clash/config.yaml

# 或者复制示例配置
sudo cp example-config.yaml /etc/clash/config.yaml
sudo nano /etc/clash/config.yaml
```

在配置文件中找到 `proxy-providers` 部分，将订阅链接替换为您的实际订阅：

```yaml
proxy-providers:
  main-subscription:
    type: http
    url: "https://your-subscription-url-here"  # 替换这里
    interval: 86400
    path: ./proxies/main.yaml
```

## 启动和管理

```bash
# 启动服务
clash-ctl start

# 查看状态
clash-ctl status

# 启用系统代理
clash-ctl proxy-enable

# 启用TUN模式（推荐）
clash-ctl tun-enable

# 查看实时日志
clash-ctl logs
```

## 验证连接

```bash
# 测试HTTP代理
curl -x http://127.0.0.1:7890 http://google.com

# 测试系统代理（启用后）
curl http://google.com

# 查看外网IP
curl http://ip-api.com/json
```

## 代理模式说明

### 1. 系统代理模式
- 适用于支持HTTP代理的应用程序
- 需要应用程序支持代理设置
- 启用：`clash-ctl proxy-enable`

### 2. TUN透明代理模式  
- 系统级别的透明代理
- 所有流量都会被代理（除规则排除的）
- 无需应用程序支持代理
- 启用：`clash-ctl tun-enable`

## Web管理界面

访问 http://127.0.0.1:9090 使用API，推荐使用第三方面板：

1. 打开 http://clash.razord.top
2. 在面板中输入API地址：`http://127.0.0.1:9090`
3. 即可在网页中管理Clash

## 常用命令速查

```bash
# 服务管理
clash-ctl start          # 启动
clash-ctl stop           # 停止  
clash-ctl restart        # 重启
clash-ctl status         # 状态
clash-ctl logs           # 日志

# 代理控制
clash-ctl proxy-enable   # 启用系统代理
clash-ctl proxy-disable  # 禁用系统代理
clash-ctl tun-enable     # 启用TUN模式
clash-ctl tun-disable    # 禁用TUN模式

# 配置管理
clash-ctl config         # 编辑配置
clash-ctl reload         # 重载配置
clash-ctl web            # 显示Web面板地址
```

## 故障排除

### 1. 服务启动失败
```bash
# 查看详细日志
journalctl -u clash -n 50

# 检查配置文件
/opt/clash/clash -t -d /etc/clash
```

### 2. 无法访问外网
- 检查订阅链接是否正确
- 验证代理服务器状态
- 确认DNS配置

### 3. TUN模式问题
```bash
# 检查TUN模块
lsmod | grep tun

# 手动加载（如需要）
sudo modprobe tun
```

## 高级配置

### 自定义规则

编辑 `/etc/clash/config.yaml`，在 `rules` 部分添加：

```yaml
rules:
  # 自定义域名代理
  - DOMAIN-SUFFIX,example.com,🚀 代理选择
  
  # 自定义IP段直连  
  - IP-CIDR,203.0.113.0/24,🎯 全球直连
  
  # 自定义端口规则
  - DST-PORT,22,🎯 全球直连
```

### 多订阅配置

可以配置多个订阅源以提高可用性：

```yaml
proxy-providers:
  subscription-1:
    type: http
    url: "https://sub1.example.com/link"
    interval: 86400
    path: ./proxies/sub1.yaml
    
  subscription-2:
    type: http
    url: "https://sub2.example.com/link"  
    interval: 86400
    path: ./proxies/sub2.yaml
```

## 性能优化

### 1. 调整日志级别
```yaml
log-level: warning  # 减少日志输出
```

### 2. 禁用IPv6（如不需要）
```yaml
ipv6: false
```

### 3. 调整健康检查间隔
```yaml
health-check:
  interval: 1800  # 30分钟检查一次
```

这样就完成了Clash的快速安装和配置！
