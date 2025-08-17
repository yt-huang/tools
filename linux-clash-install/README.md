# Linux Clash 安装脚本

这是一个用于在Ubuntu无GUI环境下安装Clash代理工具的自动化脚本，支持系统代理和TUN代理模式。

## 功能特性

- ✅ 自动检测系统架构 (amd64, arm64, armv7)
- ✅ 无人值守安装Clash核心
- ✅ **智能本地文件检测** - 自动使用本地二进制文件，跳过下载
- ✅ **自动订阅配置** - 读取 `ording-address` 文件自动配置订阅
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

### 1. 智能本地安装 (推荐)

如果您已经有本地二进制文件和订阅地址，推荐使用智能安装模式：

```bash
# 克隆仓库
git clone https://github.com/your-repo/tools.git
cd tools/linux-clash-install

# 将订阅地址保存到 ording-address 文件（可选）
echo "您的订阅链接" > ording-address

# 将下载的 mihomo 二进制文件重命名（可选）
# 例如：mv mihomo-linux-amd64-v1.18.8.gz ./
# 脚本会自动检测并使用本地文件，跳过下载

# 运行安装脚本
sudo bash clash-install.sh
```

### 2. 在线安装

```bash
# 下载脚本
wget https://raw.githubusercontent.com/your-repo/tools/main/linux-clash-install/clash-install.sh

# 添加执行权限
chmod +x clash-install.sh

# 运行安装
sudo ./clash-install.sh
```

### 3. 标准本地安装

```bash
# 克隆仓库
git clone https://github.com/your-repo/tools.git
cd tools/linux-clash-install

# 运行安装脚本
sudo bash clash-install.sh
```

## 智能安装功能详解

### 本地二进制文件检测

脚本会自动检测是否存在本地 mihomo 二进制文件：

```bash
# 支持的文件名格式（根据系统架构自动匹配）：
mihomo-linux-amd64-v1.18.8.gz    # x86_64 系统
mihomo-linux-arm64-v1.18.8.gz    # ARM64 系统  
mihomo-linux-armv7-v1.18.8.gz    # ARMv7 系统
```

**使用方法：**
1. 将下载的 mihomo 二进制文件放在脚本同目录
2. 确保文件名格式正确
3. 运行脚本时会自动检测并使用本地文件

**优势：**
- 🚀 跳过下载步骤，安装更快
- 🌐 避免网络问题导致的下载失败
- 📦 支持离线安装

### 自动订阅配置

脚本会自动读取 `ording-address` 文件中的订阅链接：

```bash
# 创建订阅地址文件
echo "https://your-subscription-url" > ording-address

# 脚本会自动：
# 1. 读取订阅地址
# 2. 验证URL格式  
# 3. 写入配置文件
# 4. 启用订阅更新
```

**支持格式：**
- HTTP/HTTPS 订阅链接
- 自动去除空格和换行符
- 支持长URL（会自动处理）

**配置效果：**
```yaml
proxy-providers:
  default:
    type: http
    url: "您的订阅链接"    # 自动填入
    interval: 86400
    path: ./proxies/default.yaml
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

### 1. Ubuntu 无GUI环境错误

**错误：** `Missing X server or $DISPLAY` 或 `Segmentation fault`

**解决方案：** 脚本已自动优化无GUI环境，包括：
- 设置正确的环境变量
- 安装必要的运行时依赖
- 配置headless模式

如果仍有问题，请参考：[Ubuntu 故障排除指南](UBUNTU-TROUBLESHOOTING.md)

### 2. 架构不匹配

**错误：** 安装验证失败

**解决方案：**
```bash
# 检查系统架构
uname -m

# 确保使用正确的二进制文件
# x86_64 → mihomo-linux-amd64-v1.18.8.gz
# aarch64 → mihomo-linux-arm64-v1.18.8.gz
```

### 3. 服务启动失败

```bash
# 查看详细日志
journalctl -u clash -n 50

# 检查配置文件语法
/opt/clash/clash -t -d /etc/clash
```

### 4. 无法访问外网

- 确保订阅链接正确配置
- 检查代理服务器是否可用
- 验证DNS设置

### 5. TUN模式无法启用

```bash
# 检查内核模块
lsmod | grep tun

# 加载TUN模块（如果未加载）
modprobe tun
```

### 6. 权限问题

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

## 最新更新 (2024-12-19)

### 🚀 智能安装功能 (新增)
- **本地文件检测**: 自动检测并使用本地 mihomo 二进制文件，跳过下载
- **自动订阅配置**: 读取 `ording-address` 文件自动配置订阅链接
- **离线安装支持**: 支持完全离线安装，无需网络连接
- **智能架构匹配**: 根据系统架构自动匹配对应的二进制文件
- **Ubuntu无GUI优化**: 自动配置headless环境，解决X11和段错误问题
- **增强错误处理**: 多级验证机制，提供详细的故障诊断信息

### 🔧 网络连接性改进
- **新增网络诊断脚本**: `network-diagnostic.sh` 用于排查网络连接问题
- **更新下载源**: 移除失效的镜像，添加更可靠的下载源
- **智能网络检测**: 安装前自动检测网络连接性
- **多重备用方案**: 包括Clash Meta作为备用选择

### 📋 可用下载源 (按优先级排序)
1. **JSDelivr CDN** - 全球CDN，相对稳定
2. **GitHub官方** - 官方发布页面（可能需要代理）
3. **GitHub代理服务** - ghproxy.com 等镜像服务
4. **Clash Meta** - 兼容版本作为备用

### 🛠 新增工具
- `network-diagnostic.sh` - 网络连接诊断脚本
- `download-sources.yaml` - 下载源配置文件

## 网络问题排查

如果遇到下载失败问题，请先运行网络诊断：

```bash
# 运行网络诊断脚本
bash network-diagnostic.sh
```

常见解决方案：

1. **DNS问题**:
```bash
sudo echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
```

2. **使用代理**:
```bash
export http_proxy=http://your-proxy:port
export https_proxy=http://your-proxy:port
sudo -E bash clash-install.sh
```

3. **手动下载**:
- 访问: https://github.com/Dreamacro/clash/releases
- 或使用: https://cdn.jsdelivr.net/gh/Dreamacro/clash/releases/

## 更新历史

- v1.1.0 (2024-12-19): 网络连接性改进，新增诊断工具
- v1.0.0: 初始版本，支持基本安装和配置
- 支持多架构自动检测
- 集成TUN模式和系统代理
- 提供完整的管理工具

## 许可证

此脚本基于MIT许可证开源。
