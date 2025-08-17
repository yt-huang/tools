# 开发环境安装工具

这是一个专门为中国网络环境优化的开发工具安装脚本，支持快速安装和配置各种常用的开发环境。

## ✨ 特性

- 🚀 **快速安装**: 一键安装多种开发环境
- 🇨🇳 **国内优化**: 使用国内镜像源，下载速度更快
- 🔧 **自动配置**: 自动配置环境变量和镜像源
- 💻 **跨平台**: 支持 Ubuntu、CentOS、macOS
- 🛡️ **安全可靠**: 使用官方源，确保软件安全性

## 📦 支持的软件

| 软件 | 描述 | 国内优化 |
|------|------|----------|
| **Docker** | 容器化平台 | ✅ 阿里云镜像源 |
| **Docker Compose** | 容器编排工具 | ✅ 包含在 Docker 安装中 |
| **Go** | Go 语言环境 | ✅ goproxy.cn 代理 |
| **Java** | Java 17 开发环境 | ✅ OpenJDK |
| **Node.js** | JavaScript 运行环境 | ✅ 淘宝 NPM 镜像 |
| **kubectl** | Kubernetes 命令行工具 | ✅ 阿里云镜像源 |
| **Clash** | 代理工具 (Ubuntu无GUI) | ✅ 支持系统代理和TUN模式 |

## 🚀 快速开始

### 1. 下载脚本

```bash
# 下载到本地
curl -fsSL https://raw.githubusercontent.com/your-repo/install.sh -o install.sh
chmod +x install.sh

# 或者如果你已经有了脚本文件
chmod +x install.sh
```

### 2. 安装 Docker 和 Docker Compose

```bash
# 仅安装 Docker（推荐用于你的需求）
./install.sh docker

# 查看安装结果
./install.sh --verify
```

### 3. 其他安装选项

```bash
# 安装所有支持的软件
./install.sh --all

# 安装多个指定软件
./install.sh docker go java

# 仅更新系统包管理器
./install.sh --update

# 查看帮助信息
./install.sh --help
```

## 📋 使用说明

### 命令行选项

```bash
./install.sh [选项] [软件名称]

选项:
    -h, --help          显示帮助信息
    -a, --all           安装所有支持的软件
    -u, --update        仅更新系统包管理器
    --verify            验证已安装的软件

支持的软件:
    docker              安装 Docker 和 Docker Compose
    go                  安装 Go 语言环境
    java                安装 Java 17
    nodejs              安装 Node.js LTS
    kubectl [版本]      安装 kubectl (默认最新版本)
    clash               安装 Clash 代理工具 (Ubuntu无GUI)
```

### 安装示例

```bash
# 示例 1: 安装 Docker（适合你的需求）
./install.sh docker

# 示例 2: 安装开发常用环境
./install.sh docker go nodejs

# 示例 3: 安装所有支持的软件
./install.sh --all

# 示例 4: 安装 Clash 代理工具 (Ubuntu无GUI)
./install.sh clash

# 示例 5: 安装 kubectl
./install.sh kubectl

# 示例 6: 验证安装状态
./install.sh --verify
```

## 🔧 Docker 安装详情

### 安装内容

1. **Docker Engine**: 核心容器引擎
2. **Docker Compose**: 容器编排工具（支持 plugin 和独立版本）
3. **国内镜像源配置**: 自动配置以下镜像源
   - 中科大镜像: `https://docker.mirrors.ustc.edu.cn`
   - 网易镜像: `https://hub-mirror.c.163.com`
   - 百度镜像: `https://mirror.baidubce.com`

### 安装后配置

安装完成后，脚本会自动：

1. 启动 Docker 服务
2. 设置开机自启动
3. 将当前用户添加到 docker 组
4. 配置国内镜像源加速

### 验证安装

```bash
# 检查 Docker 版本
docker --version

# 检查 Docker Compose 版本
docker compose version
# 或者（如果使用独立版本）
docker-compose --version

# 测试 Docker 运行
docker run hello-world

# 查看镜像源配置
docker info | grep -A 10 "Registry Mirrors"
```

## 🌏 网络环境优化

### Ubuntu/Debian 优化

- **APT 镜像源**: 阿里云镜像源
- **Docker 源**: 阿里云 Docker CE 镜像源

### CentOS/RHEL 优化

- **YUM 镜像源**: 阿里云镜像源
- **Docker 源**: 阿里云 Docker CE 镜像源

### macOS 优化

- **Homebrew**: 中科大 Homebrew Bottles 镜像
- **Docker Desktop**: 需要手动下载安装

### 其他优化

- **Go 代理**: goproxy.cn
- **NPM 镜像**: 淘宝 NPM 镜像
- **Maven**: （如果安装 Java 开发工具）阿里云 Maven 镜像

## 🛠️ 故障排除

### 常见问题

1. **权限问题**
   ```bash
   # 如果遇到权限错误，重新登录或运行：
   newgrp docker
   ```

2. **网络连接问题**
   ```bash
   # 检查网络连接
   ping 8.8.8.8
   
   # 如果网络有问题，可能需要配置代理
   export http_proxy=your_proxy
   export https_proxy=your_proxy
   ```

3. **Docker 镜像拉取慢**
   ```bash
   # 检查镜像源配置
   cat /etc/docker/daemon.json
   
   # 重启 Docker 服务
   sudo systemctl restart docker
   ```

4. **macOS Docker Desktop 问题**
   - 确保从官网下载最新版本
   - 在 Docker Desktop 设置中手动配置镜像源

### 卸载软件

如果需要卸载安装的软件：

```bash
# 卸载 Docker (Ubuntu/Debian)
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker

# 卸载 Docker (CentOS/RHEL)
sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
```

## 🔧 Clash 代理工具安装详情

### 功能特性

1. **自动安装**: 无人值守安装Clash核心和依赖
2. **系统代理**: 支持HTTP/HTTPS代理模式
3. **TUN模式**: 支持透明代理，无需应用程序支持代理
4. **systemd服务**: 自动配置系统服务，开机自启
5. **Web管理**: 内置API接口，支持Web面板管理
6. **多架构支持**: 自动检测并安装对应架构版本

### 快速开始

```bash
# 1. 安装Clash
./install.sh clash

# 2. 配置订阅链接
sudo nano /etc/clash/config.yaml

# 3. 启动服务
clash-ctl start

# 4. 启用系统代理
clash-ctl proxy-enable

# 5. 或启用TUN模式（推荐）
clash-ctl tun-enable
```

### 管理命令

```bash
# 服务管理
clash-ctl start          # 启动服务
clash-ctl stop           # 停止服务
clash-ctl restart        # 重启服务
clash-ctl status         # 查看状态
clash-ctl logs           # 查看日志

# 代理控制
clash-ctl proxy-enable   # 启用系统代理
clash-ctl proxy-disable  # 禁用系统代理
clash-ctl tun-enable     # 启用TUN模式
clash-ctl tun-disable    # 禁用TUN模式

# 配置管理
clash-ctl config         # 编辑配置文件
clash-ctl reload         # 重载配置
clash-ctl web            # 显示Web面板地址
```

### 代理端口说明

- **HTTP代理**: 127.0.0.1:7890
- **SOCKS5代理**: 127.0.0.1:7891
- **Web管理API**: 127.0.0.1:9090

### 配置文件

- **主配置**: `/etc/clash/config.yaml`
- **示例配置**: `linux-clash-install/example-config.yaml`
- **快速指南**: `linux-clash-install/QUICKSTART.md`

**注意**: Clash安装脚本目前仅支持Ubuntu无GUI环境，需要root权限。

## 📝 更新日志

### v1.1 (当前版本)
- ✅ 新增 Clash 代理工具安装支持
- ✅ 支持系统代理和TUN透明代理模式
- ✅ 完整的管理脚本和配置文件
- ✅ 支持 kubectl 安装

### v1.0
- ✅ 支持 Docker 和 Docker Compose 安装
- ✅ 支持 Go、Java、Node.js 安装
- ✅ 国内镜像源优化
- ✅ 跨平台支持 (Ubuntu, CentOS, macOS)
- ✅ 自动环境配置

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目！

## 📄 许可证

MIT License

---

**享受快速的开发环境安装体验！** 🚀
# tools
