#!/bin/bash

# 开发环境安装脚本 - 适配中国网络环境
# 支持安装: Docker, Docker Compose, Go, Java, Node.js 等
# 作者: Dev Environment Installer
# 版本: 1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "无法检测操作系统"
        exit 1
    fi
    
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "网络连接正常"
    else
        log_warning "网络连接可能有问题，建议检查网络设置"
    fi
}

# 更新系统包管理器
update_system() {
    log_info "更新系统包管理器..."
    
    case $OS in
        "ubuntu"|"debian")
            # 配置阿里云镜像源
            if ! grep -q "mirrors.aliyun.com" /etc/apt/sources.list 2>/dev/null; then
                log_info "配置阿里云 APT 镜像源..."
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
                case $OS_VERSION in
                    "20.04")
                        cat << 'EOF' | sudo tee /etc/apt/sources.list
deb https://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
                        ;;
                    "22.04")
                        cat << 'EOF' | sudo tee /etc/apt/sources.list
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF
                        ;;
                esac
            fi
            sudo apt update
            sudo apt install -y curl wget apt-transport-https ca-certificates gnupg lsb-release
            ;;
        "centos"|"rhel")
            # 配置阿里云 YUM 镜像源
            log_info "配置阿里云 YUM 镜像源..."
            sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup 2>/dev/null || true
            sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
            sudo yum makecache
            sudo yum install -y curl wget
            ;;
        "macos")
            # 检查 Homebrew
            if ! command -v brew &> /dev/null; then
                log_info "安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://gitee.com/ineo6/homebrew-install/raw/master/install.sh)"
            fi
            # 配置 Homebrew 中科大镜像
            export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
            ;;
    esac
}

# 安装 Docker
install_docker() {
    log_info "开始安装 Docker..."
    
    case $OS in
        "ubuntu"|"debian")
            # 卸载旧版本
            sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
            
            # 添加 Docker 官方 GPG 密钥
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # 添加 Docker 阿里云镜像源
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "centos"|"rhel")
            # 卸载旧版本
            sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
            
            # 添加 Docker 阿里云 YUM 源
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        "macos")
            # 检查是否已安装 Docker Desktop
            if [[ -d "/Applications/Docker.app" ]]; then
                log_warning "Docker Desktop 已安装"
                return 0
            fi
            
            log_info "请手动下载并安装 Docker Desktop for Mac"
            log_info "下载地址: https://desktop.docker.com/mac/main/amd64/Docker.dmg"
            return 0
            ;;
    esac
    
    # 启动 Docker 服务
    if [[ "$OS" != "macos" ]]; then
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # 将当前用户添加到 docker 组
        sudo usermod -aG docker $USER
        
        log_success "Docker 安装完成"
        log_info "请重新登录以使 docker 组权限生效，或运行: newgrp docker"
    fi
}

# 配置 Docker 国内镜像源
configure_docker_mirrors() {
    log_info "配置 Docker 国内镜像源..."
    
    if [[ "$OS" == "macos" ]]; then
        log_info "macOS 用户请在 Docker Desktop 设置中手动配置镜像源"
        log_info "建议镜像源："
        echo "  - https://docker.mirrors.ustc.edu.cn"
        echo "  - https://hub-mirror.c.163.com"
        echo "  - https://mirror.baidubce.com"
        return 0
    fi
    
    sudo mkdir -p /etc/docker
    
    cat << 'EOF' | sudo tee /etc/docker/daemon.json
{
    "registry-mirrors": [
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com",
        "https://mirror.baidubce.com"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    # 重启 Docker 服务
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    
    log_success "Docker 镜像源配置完成"
}

# 安装 Docker Compose (独立版本)
install_docker_compose() {
    log_info "安装 Docker Compose..."
    
    # 检查是否已安装 docker compose plugin
    if docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose (plugin) 已安装"
        return 0
    fi
    
    # 检查是否已安装独立版本的 docker-compose
    if command -v docker-compose >/dev/null 2>&1; then
        log_success "Docker Compose (独立版本) 已安装: $(docker-compose --version)"
        return 0
    fi
    
    # 获取最新版本
    local compose_version="v2.24.5"  # 默认使用稳定版本
    
    # 尝试从GitHub API获取最新版本
    if curl -s --connect-timeout 5 https://api.github.com/repos/docker/compose/releases/latest >/dev/null 2>&1; then
        local latest_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")' 2>/dev/null)
        if [[ -n "$latest_version" ]]; then
            compose_version="$latest_version"
            log_info "获取到最新版本: $compose_version"
        fi
    else
        log_warning "无法访问GitHub API，使用默认版本: $compose_version"
    fi
    
    case $OS in
        "ubuntu"|"debian"|"centos"|"rhel")
            log_info "下载 Docker Compose 二进制文件..."
            
            # 确定系统架构
            local arch=$(uname -m)
            case $arch in
                "x86_64") arch="x86_64";;
                "aarch64") arch="aarch64";;
                "arm64") arch="aarch64";;
                *) log_error "不支持的架构: $arch"; return 1;;
            esac
            
            # 尝试多个下载源
            local download_success=false
            local download_urls=(
                "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}"
                "https://ghproxy.com/https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}"
                "https://hub.fastgit.xyz/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}"
            )
            
            for url in "${download_urls[@]}"; do
                log_info "尝试从 $url 下载..."
                if sudo curl -L "$url" -o /usr/local/bin/docker-compose --connect-timeout 10 --max-time 60; then
                    download_success=true
                    log_success "下载成功"
                    break
                else
                    log_warning "从 $url 下载失败，尝试下一个源..."
                fi
            done
            
            if [[ "$download_success" == false ]]; then
                log_error "所有下载源都失败，无法安装 Docker Compose"
                return 1
            fi
            
            # 设置执行权限
            sudo chmod +x /usr/local/bin/docker-compose
            
            # 创建软链接
            sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
            
            # 验证安装
            if docker-compose --version >/dev/null 2>&1; then
                log_success "Docker Compose 安装成功: $(docker-compose --version)"
            else
                log_error "Docker Compose 安装验证失败"
                return 1
            fi
            ;;
        "macos")
            log_info "使用 Homebrew 安装 Docker Compose..."
            if command -v brew >/dev/null 2>&1; then
                brew install docker-compose
                if docker-compose --version >/dev/null 2>&1; then
                    log_success "Docker Compose 安装成功: $(docker-compose --version)"
                else
                    log_error "Docker Compose 安装失败"
                    return 1
                fi
            else
                log_error "Homebrew 未安装，请先安装 Homebrew"
                return 1
            fi
            ;;
    esac
    
    log_success "Docker Compose 安装完成"
}

# 安装 Go
install_go() {
    log_info "安装 Go 语言环境..."
    
    # 获取最新版本
    local go_version=$(curl -s https://golang.org/VERSION?m=text 2>/dev/null | head -n1)
    if [[ -z "$go_version" ]]; then
        go_version="go1.21.3"  # 备用版本
    fi
    
    case $OS in
        "ubuntu"|"debian"|"centos"|"rhel")
            # 使用国内镜像下载
            local arch=$(uname -m)
            case $arch in
                "x86_64") arch="amd64";;
                "aarch64") arch="arm64";;
            esac
            
            wget -O /tmp/${go_version}.linux-${arch}.tar.gz https://golang.google.cn/dl/${go_version}.linux-${arch}.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/${go_version}.linux-${arch}.tar.gz
            
            # 配置环境变量
            if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
                echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.bashrc
                echo 'export GOSUMDB=sum.golang.google.cn' >> ~/.bashrc
            fi
            ;;
        "macos")
            brew install go
            # 配置 Go 代理
            echo 'export GOPROXY=https://goproxy.cn,direct' >> ~/.zshrc
            echo 'export GOSUMDB=sum.golang.google.cn' >> ~/.zshrc
            ;;
    esac
    
    log_success "Go 安装完成"
    log_info "请重新加载终端或运行: source ~/.bashrc (Linux) 或 source ~/.zshrc (macOS)"
}

# 安装 Java
install_java() {
    log_info "安装 Java 环境..."
    
    case $OS in
        "ubuntu"|"debian")
            sudo apt update
            sudo apt install -y openjdk-17-jdk
            ;;
        "centos"|"rhel")
            sudo yum install -y java-17-openjdk java-17-openjdk-devel
            ;;
        "macos")
            brew install openjdk@17
            # 创建软链接
            sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk
            ;;
    esac
    
    log_success "Java 17 安装完成"
}

# 安装 Node.js
install_nodejs() {
    log_info "安装 Node.js..."
    
    case $OS in
        "ubuntu"|"debian")
            # 使用 NodeSource 仓库
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        "centos"|"rhel")
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
            ;;
        "macos")
            brew install node
            ;;
    esac
    
    # 配置 npm 国内镜像
    npm config set registry https://registry.npmmirror.com
    
    log_success "Node.js 安装完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装结果..."
    
    echo -e "\n${BLUE}=== 安装验证 ===${NC}"
    
    # Docker
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker: $(docker --version)"
    else
        echo -e "${RED}✗${NC} Docker: 未安装"
    fi
    
    # Docker Compose
    if docker compose version &> /dev/null || command -v docker-compose &> /dev/null; then
        if docker compose version &> /dev/null; then
            echo -e "${GREEN}✓${NC} Docker Compose: $(docker compose version --short)"
        else
            echo -e "${GREEN}✓${NC} Docker Compose: $(docker-compose --version)"
        fi
    else
        echo -e "${RED}✗${NC} Docker Compose: 未安装"
    fi
    
    # Go
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✓${NC} Go: $(go version)"
    else
        echo -e "${RED}✗${NC} Go: 未安装"
    fi
    
    # Java
    if command -v java &> /dev/null; then
        echo -e "${GREEN}✓${NC} Java: $(java -version 2>&1 | head -n1)"
    else
        echo -e "${RED}✗${NC} Java: 未安装"
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node.js: $(node --version)"
        echo -e "${GREEN}✓${NC} npm: $(npm --version)"
    else
        echo -e "${RED}✗${NC} Node.js: 未安装"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
开发环境安装脚本 - 适配中国网络环境

用法: $0 [选项] [软件名称]

选项:
    -h, --help          显示此帮助信息
    -a, --all           安装所有支持的软件
    -u, --update        仅更新系统包管理器
    --verify            验证已安装的软件

支持的软件:
    docker              安装 Docker 和 Docker Compose
    go                  安装 Go 语言环境
    java                安装 Java 17
    nodejs              安装 Node.js LTS

示例:
    $0 docker           # 仅安装 Docker
    $0 docker go        # 安装 Docker 和 Go
    $0 -a               # 安装所有软件
    $0 --verify         # 验证安装

注意:
    - 脚本已针对中国网络环境优化，使用国内镜像源
    - 某些操作需要 sudo 权限
    - macOS 用户需要先安装 Homebrew
EOF
}

# 主函数
main() {
    echo -e "${BLUE}开发环境安装脚本 - 中国网络环境优化版${NC}"
    echo "================================================"
    
    # 检查参数
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    # 解析参数
    install_all=false
    update_only=false
    verify_only=false
    software_list=()
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                install_all=true
                shift
                ;;
            -u|--update)
                update_only=true
                shift
                ;;
            --verify)
                verify_only=true
                shift
                ;;
            docker|go|java|nodejs)
                software_list+=("$1")
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 仅验证安装
    if [[ "$verify_only" == true ]]; then
        verify_installation
        exit 0
    fi
    
    # 检测系统环境
    detect_os
    check_network
    
    # 更新系统
    update_system
    
    # 仅更新系统
    if [[ "$update_only" == true ]]; then
        log_success "系统更新完成"
        exit 0
    fi
    
    # 安装软件
    if [[ "$install_all" == true ]]; then
        software_list=("docker" "go" "java" "nodejs")
    fi
    
    for software in "${software_list[@]}"; do
        case $software in
            "docker")
                install_docker
                configure_docker_mirrors
                install_docker_compose
                ;;
            "go")
                install_go
                ;;
            "java")
                install_java
                ;;
            "nodejs")
                install_nodejs
                ;;
        esac
    done
    
    # 验证安装
    verify_installation
    
    echo -e "\n${GREEN}安装完成！${NC}"
    log_info "建议重新启动终端或重新登录以确保所有环境变量生效"
}

# 脚本入口
main "$@"
