# Linux Clash 安装脚本

这是一个用于在Ubuntu无GUI环境下安装Clash代理工具的自动化脚本，支持系统代理和TUN代理模式。

## 功能特性

- ✅ 自动检测系统架构 (amd64, arm64, armv7)
- ✅ 无人值守安装Clash核心
- ✅ 配置systemd系统服务
- ✅ 支持系统代理模式 (HTTP/HTTPS)
- ✅ 支持TUN透明代理模式
- ✅ 提供完整的管理工具
- ✅ Web管理界面
- ✅ 安全配置和权限控制

## 系统要求

- Ubuntu 18.04+ (其他Debian系发行版理论支持)
- systemd支持
- root权限
- 网络连接

## 快速安装

### 1. 下载并运行安装脚本

```bash
# 下载脚本
wget https://raw.githubusercontent.com/your-repo/tools/main/linux-clash-install/clash-install.sh

# 添加执行权限
chmod +x clash-install.sh

# 运行安装
sudo ./clash-install.sh
```

### 2. 本地安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/tools.git
cd tools/linux-clash-install

# 运行安装脚本
sudo bash clash-install.sh
```

## 配置订阅

安装完成后，需要配置您的代理订阅：

1. 编辑配置文件：
```bash
sudo nano /etc/clash/config.yaml
```

2. 在 `proxy-providers` 部分添加您的订阅链接：
```yaml
proxy-providers:
  default:
    type: http
    url: "您的订阅链接"  # 替换为实际订阅链接
    interval: 86400
    path: ./proxies/default.yaml
```

3. 重启服务：
```bash
clash-ctl restart
```

## 使用方法

### 服务管理

```bash
# 启动服务
clash-ctl start

# 停止服务
clash-ctl stop

# 重启服务
clash-ctl restart

# 查看状态
clash-ctl status

# 查看日志
clash-ctl logs
```

### 代理配置

#### 系统代理模式

```bash
# 启用系统代理
clash-ctl proxy-enable

# 禁用系统代理
clash-ctl proxy-disable
```

启用后，所有支持HTTP代理的应用程序都会自动使用代理。

#### TUN透明代理模式

```bash
# 启用TUN模式
clash-ctl tun-enable

# 禁用TUN模式
clash-ctl tun-disable
```

TUN模式提供更全面的代理覆盖，包括不支持代理的应用程序。

### Web管理界面

1. 访问内置API：http://127.0.0.1:9090
2. 推荐使用第三方面板：http://clash.razord.top

在面板中输入API地址 `http://127.0.0.1:9090` 即可管理。

## 代理端口说明

- **HTTP代理**: 127.0.0.1:7890
- **SOCKS5代理**: 127.0.0.1:7891
- **透明代理**: 127.0.0.1:7892
- **TProxy端口**: 127.0.0.1:7893
- **混合端口**: 127.0.0.1:7890
- **API端口**: 127.0.0.1:9090

## 目录结构

```
/opt/clash/           # Clash主目录
├── clash             # Clash可执行文件

/etc/clash/           # 配置文件目录
├── config.yaml       # 主配置文件
└── proxies/          # 代理文件缓存

/var/log/clash/       # 日志目录

/usr/local/bin/       # 管理脚本
├── clash-ctl         # 主控制脚本
├── clash-proxy-enable
├── clash-proxy-disable
├── clash-tun-enable
└── clash-tun-disable
```

## 常见问题

### 1. 服务启动失败

```bash
# 查看详细日志
journalctl -u clash -n 50

# 检查配置文件语法
/opt/clash/clash -t -d /etc/clash
```

### 2. 无法访问外网

- 确保订阅链接正确配置
- 检查代理服务器是否可用
- 验证DNS设置

### 3. TUN模式无法启用

```bash
# 检查内核模块
lsmod | grep tun

# 加载TUN模块（如果未加载）
modprobe tun
```

### 4. 权限问题

确保以root权限运行安装脚本：
```bash
sudo ./clash-install.sh
```

## 卸载

```bash
# 停止并禁用服务
sudo systemctl stop clash
sudo systemctl disable clash

# 删除服务文件
sudo rm /etc/systemd/system/clash.service

# 删除用户和文件
sudo userdel clash
sudo rm -rf /opt/clash
sudo rm -rf /etc/clash
sudo rm -rf /var/log/clash

# 删除管理脚本
sudo rm /usr/local/bin/clash-*

# 重新加载systemd
sudo systemctl daemon-reload
```

## 安全注意事项

1. 定期更新Clash版本
2. 保护好订阅链接，避免泄露
3. 使用HTTPS订阅链接
4. 定期检查日志文件
5. 限制Web API访问（生产环境建议设置密码）

## 技术支持

如果遇到问题，请：

1. 查看日志：`clash-ctl logs`
2. 检查配置：`clash-ctl config`
3. 验证服务状态：`clash-ctl status`

## 更新历史

- v1.0.0: 初始版本，支持基本安装和配置
- 支持多架构自动检测
- 集成TUN模式和系统代理
- 提供完整的管理工具

## 许可证

此脚本基于MIT许可证开源。
