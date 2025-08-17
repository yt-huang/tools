# Node.js 安装功能指南

## 概述

`install.sh` 脚本已增强了 Node.js 安装功能，针对中国网络环境进行了深度优化，支持版本选择、多镜像源、包管理器配置和完整的开发环境设置。

## 主要特性

### 🚀 版本管理
- **LTS 版本支持**: 自动获取并安装最新的 LTS (长期支持) 版本
- **指定版本安装**: 支持安装任意指定的 Node.js 版本
- **版本格式灵活**: 支持 `v20.10.0`、`20.10.0`、`lts` 等格式
- **版本检测**: 智能检测已安装版本，避免重复安装

### 🌐 中国网络优化
- **多镜像源**: 清华大学、中科大、阿里云、npm 淘宝镜像
- **智能切换**: 自动尝试多个下载源，确保安装成功
- **网络超时处理**: 合理的超时设置和重试机制

### 📦 包管理器支持
- **npm**: 默认包管理器，自动配置国内镜像
- **Yarn**: 自动安装和配置 Yarn 包管理器
- **pnpm**: 自动安装和配置 pnpm 包管理器
- **镜像源配置**: 所有包管理器都配置国内镜像源

### 🛠 开发环境配置
- **全局开发工具**: Vue CLI、React CLI、TypeScript、nodemon、PM2 等
- **工作目录**: 自动创建标准的开发目录结构
- **环境变量**: 配置开发环境变量和便捷别名
- **Shell 集成**: 支持 bash 和 zsh 环境配置

### 🔧 多平台支持
- **Ubuntu/Debian**: 使用 APT 包管理器和二进制安装
- **CentOS/RHEL**: 使用 YUM 包管理器和二进制安装
- **macOS**: 使用 Homebrew 和 n 版本管理器

## 使用方法

### 基本用法

```bash
# 安装 Node.js LTS 版本
./install.sh nodejs

# 安装指定版本
./install.sh nodejs v20.10.0
./install.sh nodejs 18.19.0

# 明确安装 LTS 版本
./install.sh nodejs lts
```

### 与其他软件组合安装

```bash
# 同时安装 Docker 和 Node.js
./install.sh docker nodejs

# 安装完整开发环境
./install.sh docker go java nodejs
```

### 验证安装

```bash
# 验证所有已安装软件
./install.sh --verify
```

## 安装流程

### 1. 版本检测
```
检测已安装版本 → 版本比较 → 用户确认 → 继续安装/跳过
```

### 2. 系统平台检测
```
检测操作系统 → 选择安装方法 → 配置平台特定设置
```

### 3. 安装方法选择

#### Ubuntu/Debian 系统
1. **包管理器安装 (优先)**
   - 清华大学镜像源的 NodeSource 仓库
   - 阿里云镜像源的 NodeSource 仓库
   
2. **二进制安装 (备用)**
   - 多个国内镜像源下载
   - 自动解压和安装到系统目录

#### CentOS/RHEL 系统
1. **YUM 仓库安装**
   - EPEL 仓库配置
   - 清华镜像源的 NodeSource 仓库
   
2. **二进制安装 (备用)**
   - 同 Ubuntu 系统的二进制安装流程

#### macOS 系统
1. **Homebrew 安装 (LTS)**
   - 使用 `brew install node`
   
2. **n 版本管理器 (指定版本)**
   - 安装 n 工具
   - 使用 n 管理多版本 Node.js

### 4. 环境配置
```
npm 镜像配置 → 包管理器安装 → 开发工具安装 → 环境变量设置
```

### 5. 验证测试
```
Node.js 版本检查 → npm 功能测试 → 运行时测试 → 完整性验证
```

## 镜像源配置

### npm 镜像源
```bash
registry=https://registry.npmmirror.com
disturl=https://npmmirror.com/dist
electron_mirror=https://npmmirror.com/mirrors/electron/
sass_binary_site=https://npmmirror.com/mirrors/node-sass/
```

### 下载镜像源 (按优先级)
1. **中科大镜像**: `https://mirrors.ustc.edu.cn/node/`
2. **清华镜像**: `https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/`
3. **淘宝镜像**: `https://npm.taobao.org/mirrors/node/`
4. **官方源**: `https://nodejs.org/dist/` (备用)

## 开发工具

### 自动安装的全局包
- **@vue/cli**: Vue.js 项目脚手架
- **create-react-app**: React 项目脚手架
- **typescript**: TypeScript 编译器
- **nodemon**: 开发服务器自动重启
- **pm2**: Node.js 进程管理器
- **http-server**: 静态文件服务器
- **live-server**: 开发服务器

### 开发目录结构
```
$HOME/workspace/
├── nodejs/          # Node.js 项目
├── vue/            # Vue.js 项目
└── react/          # React 项目
```

### 环境变量和别名
```bash
# 环境变量
export NODE_ENV=development
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"

# 便捷别名
alias npmls='npm list -g --depth=0'
alias npmclean='npm cache clean --force'
alias yarnls='yarn global list'
alias pnpmls='pnpm list -g'
```

## 故障排除

### 常见问题

#### 1. 网络连接问题
**问题**: 下载超时或连接失败
**解决方案**:
- 脚本会自动尝试多个镜像源
- 检查网络连接和防火墙设置
- 使用代理网络环境

#### 2. 权限问题
**问题**: 无法写入系统目录
**解决方案**:
- 使用 `sudo` 运行脚本
- 检查用户权限设置

#### 3. 版本冲突
**问题**: 已安装不同版本的 Node.js
**解决方案**:
- 脚本会提示是否覆盖安装
- 手动卸载旧版本后重新安装

#### 4. 包管理器安装失败
**问题**: Yarn 或 pnpm 安装失败
**解决方案**:
- 检查 npm 全局安装权限
- 配置 npm 全局安装目录

### 手动验证

```bash
# 检查 Node.js 版本
node --version

# 检查 npm 版本
npm --version

# 测试 Node.js 运行
echo 'console.log("Hello Node.js!")' | node

# 检查全局包
npm list -g --depth=0

# 检查镜像源配置
npm config get registry
```

## 更新日志

### v2.0 (2024-12-19)
- ✅ 完全重写 Node.js 安装功能
- ✅ 支持版本选择和智能检测
- ✅ 添加多个国内镜像源
- ✅ 集成 Yarn 和 pnpm 包管理器
- ✅ 自动安装开发工具和环境配置
- ✅ 增强错误处理和验证功能
- ✅ 支持多平台安装方法

### v1.0 (原始版本)
- 基本的 Node.js LTS 安装
- 简单的 npm 镜像源配置

## 贡献指南

如需改进 Node.js 安装功能，请注意：

1. **保持向后兼容**: 确保现有用法仍然有效
2. **中国网络优化**: 优先使用国内镜像源
3. **错误处理**: 提供清晰的错误信息和解决建议
4. **多平台支持**: 确保在不同操作系统上正常工作
5. **文档更新**: 同步更新相关文档

## 技术支持

如果遇到问题，请提供以下信息：

1. **操作系统**: `cat /etc/os-release` (Linux) 或 `sw_vers` (macOS)
2. **架构**: `uname -m`
3. **网络环境**: 是否使用代理
4. **错误日志**: 完整的错误输出
5. **已安装版本**: `node --version` 和 `npm --version`

---

**注意**: 此功能已针对中国网络环境深度优化，在海外使用时某些镜像源可能访问较慢，但仍有官方源作为备用。
