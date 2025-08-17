#!/bin/bash

# Linux Clash 安装脚本 - 无GUI Ubuntu系统
# 支持系统代理和TUN代理模式
# Author: Auto-generated script
# 更新日期: 2024-12-19
# 
# 如果遇到下载问题，请先运行网络诊断脚本:
#   bash network-diagnostic.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
# 注意: 原 Dreamacro/clash 仓库已删除，现使用 mihomo (Clash Meta)
CLASH_VERSION="1.18.8"  # 使用最新的 mihomo 版本
CLASH_USER="clash"
CLASH_HOME="/opt/clash"
CLASH_CONFIG_DIR="/etc/clash"
CLASH_LOG_DIR="/var/log/clash"
SERVICE_NAME="clash"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本必须以root权限运行${NC}"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检查系统兼容性
check_system() {
    echo -e "${BLUE}检查系统兼容性...${NC}"
    
    # 检查是否为Ubuntu
    if ! grep -q "Ubuntu" /etc/os-release; then
        echo -e "${YELLOW}警告: 此脚本主要为Ubuntu设计，其他发行版可能需要调整${NC}"
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            CLASH_ARCH="amd64"
            ;;
        aarch64|arm64)
            CLASH_ARCH="arm64"
            ;;
        armv7l)
            CLASH_ARCH="armv7"
            ;;
        *)
            echo -e "${RED}错误: 不支持的架构: $ARCH${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}系统检查通过 - 架构: $ARCH -> $CLASH_ARCH${NC}"
}

# 安装依赖
install_dependencies() {
    echo -e "${BLUE}安装系统依赖...${NC}"
    
    apt-get update
    apt-get install -y curl wget unzip systemd iptables
    
    # 检查systemd是否可用
    if ! systemctl --version >/dev/null 2>&1; then
        echo -e "${RED}错误: systemd 不可用，此脚本需要systemd支持${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}依赖安装完成${NC}"
}

# 创建用户和目录
create_user_and_dirs() {
    echo -e "${BLUE}创建Clash用户和目录...${NC}"
    
    # 创建clash用户
    if ! id "$CLASH_USER" &>/dev/null; then
        useradd -r -s /bin/false -d "$CLASH_HOME" "$CLASH_USER"
        echo -e "${GREEN}用户 $CLASH_USER 创建成功${NC}"
    else
        echo -e "${YELLOW}用户 $CLASH_USER 已存在${NC}"
    fi
    
    # 创建目录
    mkdir -p "$CLASH_HOME"
    mkdir -p "$CLASH_CONFIG_DIR"
    mkdir -p "$CLASH_LOG_DIR"
    
    # 设置权限
    chown -R "$CLASH_USER:$CLASH_USER" "$CLASH_HOME"
    chown -R "$CLASH_USER:$CLASH_USER" "$CLASH_CONFIG_DIR"
    chown -R "$CLASH_USER:$CLASH_USER" "$CLASH_LOG_DIR"
    
    echo -e "${GREEN}目录创建完成${NC}"
}

# 检查网络连接性
check_network_connectivity() {
    echo -e "${BLUE}检查网络连接性...${NC}"
    
    # 测试基本网络连接
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${YELLOW}警告: 无法连接到互联网，可能会影响下载${NC}"
        return 1
    fi
    
    # 测试 DNS 解析
    if ! nslookup github.com >/dev/null 2>&1; then
        echo -e "${YELLOW}警告: DNS 解析存在问题，建议设置公共 DNS${NC}"
        echo -e "${BLUE}设置公共 DNS: echo 'nameserver 8.8.8.8' >> /etc/resolv.conf${NC}"
        return 1
    fi
    
    # 测试 GitHub 连接性
    if curl -s --connect-timeout 10 --max-time 30 https://github.com >/dev/null 2>&1; then
        echo -e "${GREEN}网络连接正常，可以访问 GitHub${NC}"
        return 0
    else
        echo -e "${YELLOW}警告: 无法直接访问 GitHub，将优先使用镜像源${NC}"
        return 1
    fi
}

# 下载Clash
download_clash() {
    echo -e "${BLUE}下载Clash核心...${NC}"
    
    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    LOCAL_BINARY="${SCRIPT_DIR}/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
    
    # 检查本地是否存在二进制文件
    if [[ -f "$LOCAL_BINARY" ]]; then
        echo -e "${GREEN}发现本地二进制文件: $LOCAL_BINARY${NC}"
        echo -e "${BLUE}使用本地文件，跳过下载...${NC}"
        
        # 验证文件是否有效
        if [[ -s "$LOCAL_BINARY" ]]; then
            TEMP_FILE="$LOCAL_BINARY"
            echo -e "${GREEN}本地文件验证通过，继续安装...${NC}"
            # 跳转到安装部分
            install_local_binary
            return 0
        else
            echo -e "${YELLOW}本地文件无效或为空，继续在线下载...${NC}"
        fi
    else
        echo -e "${YELLOW}未发现本地二进制文件，开始在线下载...${NC}"
    fi
    
    TEMP_FILE="/tmp/clash-linux-${CLASH_ARCH}.gz"
    
    # 下载源列表（2024年12月更新 - 使用 mihomo/Clash Meta）
    local download_urls=(
        # mihomo (Clash Meta) 官方 - 推荐
        "https://github.com/MetaCubeX/mihomo/releases/download/v${CLASH_VERSION}/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
        # JSDelivr CDN - 相对稳定
        "https://cdn.jsdelivr.net/gh/MetaCubeX/mihomo@v${CLASH_VERSION}/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
        # GitHub代理源
        "https://ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${CLASH_VERSION}/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
        "https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${CLASH_VERSION}/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
    )
    
    local download_success=false
    
    for url in "${download_urls[@]}"; do
        echo -e "${BLUE}尝试从国内镜像源下载: ${url}${NC}"
        
        # 使用wget下载，设置超时和重试
        if wget --timeout=30 --tries=3 --retry-connrefused -O "$TEMP_FILE" "$url" 2>/dev/null; then
            download_success=true
            echo -e "${GREEN}下载成功！${NC}"
            break
        else
            echo -e "${YELLOW}下载失败，尝试下一个镜像源...${NC}"
            rm -f "$TEMP_FILE" 2>/dev/null
        fi
    done
    
    if [[ "$download_success" == false ]]; then
        echo -e "${RED}所有下载源都失败，尝试使用curl...${NC}"
        
        # 备用：使用curl尝试下载
        for url in "${download_urls[@]}"; do
            echo -e "${BLUE}使用curl尝试: ${url}${NC}"
            
            if curl -L --connect-timeout 30 --max-time 120 --retry 3 -o "$TEMP_FILE" "$url" 2>/dev/null; then
                download_success=true
                echo -e "${GREEN}curl下载成功！${NC}"
                break
            else
                echo -e "${YELLOW}curl下载失败，尝试下一个源...${NC}"
                rm -f "$TEMP_FILE" 2>/dev/null
            fi
        done
    fi
    
    if [[ "$download_success" == false ]]; then
        echo -e "${RED}所有下载源都失败，尝试备用下载方案...${NC}"
        
        # 备用方案：尝试下载旧版 Clash Meta
        echo -e "${YELLOW}尝试下载旧版 Clash Meta 作为替代方案...${NC}"
        local meta_urls=(
            "https://github.com/MetaCubeX/Clash.Meta/releases/download/v1.18.0/clash.meta-linux-${CLASH_ARCH}-v1.18.0.gz"
            "https://cdn.jsdelivr.net/gh/MetaCubeX/Clash.Meta@v1.18.0/clash.meta-linux-${CLASH_ARCH}-v1.18.0.gz"
        )
        
        for meta_url in "${meta_urls[@]}"; do
            echo -e "${BLUE}尝试下载 Clash Meta: ${meta_url}${NC}"
            if wget --timeout=30 --tries=3 -O "$TEMP_FILE" "$meta_url" 2>/dev/null; then
                download_success=true
                echo -e "${GREEN}Clash Meta 下载成功！${NC}"
                break
            fi
        done
        
        if [[ "$download_success" == false ]]; then
            echo -e "${RED}所有下载源都失败，无法下载Clash核心${NC}"
            echo -e "${YELLOW}请尝试以下解决方案：${NC}"
            echo ""
            echo -e "${BLUE}方案1 - 手动下载安装 mihomo (推荐)：${NC}"
            echo "1. 访问 https://github.com/MetaCubeX/mihomo/releases"
            echo "2. 下载 mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
            echo "3. 解压: gunzip mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}.gz"
            echo "4. 重命名: mv mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION} clash"
            echo "5. 移动到目标位置: sudo mv clash $CLASH_HOME/"
            echo "6. 设置执行权限: sudo chmod +x $CLASH_HOME/clash"
            echo "7. 设置所有者: sudo chown $CLASH_USER:$CLASH_USER $CLASH_HOME/clash"
            echo ""
            echo -e "${BLUE}方案2 - 使用代理重新运行脚本：${NC}"
            echo "export http_proxy=http://your-proxy:port"
            echo "export https_proxy=http://your-proxy:port"
            echo "sudo -E bash $0"
            echo ""
            echo -e "${BLUE}方案3 - 使用Docker镜像：${NC}"
            echo "curl -fsSL https://get.docker.com | bash"
            echo "docker pull metacubex/mihomo"
            echo ""
            echo -e "${BLUE}备用下载地址：${NC}"
            echo "- https://github.com/MetaCubeX/mihomo/releases"
            echo "- https://cdn.jsdelivr.net/gh/MetaCubeX/mihomo/releases/"
            
            read -p "是否要继续脚本剩余部分的安装？(y/N): " continue_install
            if [[ "$continue_install" != "y" && "$continue_install" != "Y" ]]; then
                exit 1
            else
                echo -e "${YELLOW}跳过 Clash 核心下载，继续配置其他组件...${NC}"
                return 0
            fi
        fi
    fi
    
    # 验证下载的文件
    if [[ ! -f "$TEMP_FILE" ]] || [[ ! -s "$TEMP_FILE" ]]; then
        echo -e "${RED}下载的文件无效或为空${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}解压Clash核心...${NC}"
    
    # 解压并安装
    if ! gunzip -f "$TEMP_FILE"; then
        echo -e "${RED}解压失败，文件可能损坏${NC}"
        exit 1
    fi
    
    # 移动到目标位置（处理不同的文件名）
    EXTRACTED_FILE="/tmp/clash-linux-${CLASH_ARCH}"
    if [[ -f "/tmp/mihomo-linux-${CLASH_ARCH}" ]]; then
        EXTRACTED_FILE="/tmp/mihomo-linux-${CLASH_ARCH}"
    elif [[ -f "/tmp/clash.meta-linux-${CLASH_ARCH}" ]]; then
        EXTRACTED_FILE="/tmp/clash.meta-linux-${CLASH_ARCH}"
    fi
    
    mv "$EXTRACTED_FILE" "$CLASH_HOME/clash"
    chmod +x "$CLASH_HOME/clash"
    chown "$CLASH_USER:$CLASH_USER" "$CLASH_HOME/clash"
    
    # 验证可执行文件
    if "$CLASH_HOME/clash" -v >/dev/null 2>&1; then
        echo -e "${GREEN}Clash核心安装成功: $("$CLASH_HOME/clash" -v)${NC}"
    else
        echo -e "${RED}Clash核心安装验证失败${NC}"
        exit 1
    fi
}

# 安装本地二进制文件
install_local_binary() {
    echo -e "${BLUE}安装本地二进制文件...${NC}"
    
    # 验证下载的文件
    if [[ ! -f "$TEMP_FILE" ]] || [[ ! -s "$TEMP_FILE" ]]; then
        echo -e "${RED}本地文件无效或为空${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}解压Clash核心...${NC}"
    
    # 创建临时解压目录
    TEMP_DIR="/tmp/clash-extract-$$"
    mkdir -p "$TEMP_DIR"
    
    # 复制文件到临时目录进行解压
    cp "$TEMP_FILE" "$TEMP_DIR/clash.gz"
    
    # 解压并安装
    if ! gunzip -f "$TEMP_DIR/clash.gz"; then
        echo -e "${RED}解压失败，文件可能损坏${NC}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # 移动到目标位置（处理不同的文件名）
    EXTRACTED_FILE="$TEMP_DIR/clash"
    if [[ -f "$TEMP_DIR/mihomo-linux-${CLASH_ARCH}" ]]; then
        EXTRACTED_FILE="$TEMP_DIR/mihomo-linux-${CLASH_ARCH}"
    elif [[ -f "$TEMP_DIR/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}" ]]; then
        EXTRACTED_FILE="$TEMP_DIR/mihomo-linux-${CLASH_ARCH}-v${CLASH_VERSION}"
    fi
    
    mv "$EXTRACTED_FILE" "$CLASH_HOME/clash"
    chmod +x "$CLASH_HOME/clash"
    chown "$CLASH_USER:$CLASH_USER" "$CLASH_HOME/clash"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    # 验证可执行文件
    if "$CLASH_HOME/clash" -v >/dev/null 2>&1; then
        echo -e "${GREEN}本地Clash核心安装成功: $("$CLASH_HOME/clash" -v)${NC}"
    else
        echo -e "${RED}本地Clash核心安装验证失败${NC}"
        exit 1
    fi
}

# 创建配置文件
create_config() {
    echo -e "${BLUE}创建Clash配置文件...${NC}"
    
    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SUBSCRIPTION_FILE="${SCRIPT_DIR}/ording-address"
    
    # 读取订阅地址
    SUBSCRIPTION_URL=""
    if [[ -f "$SUBSCRIPTION_FILE" ]]; then
        SUBSCRIPTION_URL=$(cat "$SUBSCRIPTION_FILE" | head -n 1 | tr -d '\r\n')
        echo -e "${GREEN}发现订阅地址文件，自动配置订阅链接${NC}"
        echo -e "${BLUE}订阅地址: ${SUBSCRIPTION_URL}${NC}"
    else
        echo -e "${YELLOW}未发现订阅地址文件，使用默认配置${NC}"
    fi
    
    # 根据是否有订阅地址生成不同的配置
    if [[ -n "$SUBSCRIPTION_URL" ]]; then
        cat > "$CLASH_CONFIG_DIR/config.yaml" << EOF
# Clash配置文件
port: 7890
socks-port: 7891
redir-port: 7892
tproxy-port: 7893
mixed-port: 7890

# HTTP(S) and SOCKS5 server on the same port
allow-lan: true
bind-address: "*"
mode: rule
log-level: info
ipv6: false

# RESTful web API listening address
external-controller: 127.0.0.1:9090
secret: ""

# TUN配置
tun:
  enable: true
  stack: system
  device: clash-tun
  auto-route: true
  auto-detect-interface: true
  dns-hijack:
    - 8.8.8.8:53
    - 8.8.4.4:53

# DNS配置（针对国内网络环境优化）
dns:
  enable: true
  listen: 0.0.0.0:1053
  ipv6: false
  default-nameserver:
    - 223.5.5.5        # 阿里DNS
    - 223.6.6.6        # 阿里DNS备用
    - 114.114.114.114  # 114DNS
    - 119.29.29.29     # 腾讯DNS
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - "*.lan"
    - "*.local"
    - localhost.ptlogin2.qq.com
    - "+.srv.nintendo.net"
    - "+.stun.playstation.net"
    - "+.msftconnecttest.com"
    - "+.msftncsi.com"
  nameserver:
    - https://dns.alidns.com/dns-query    # 阿里DoH
    - https://doh.pub/dns-query           # 腾讯DoH
    - https://doh.360.cn/dns-query        # 360DoH
    - tls://dns.rubyfish.cn:853           # 红鱼DoT
  fallback:
    - https://1.1.1.1/dns-query          # CloudFlare
    - https://8.8.8.8/dns-query          # Google DNS
    - tls://8.8.4.4:853                  # Google DoT
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

# 代理提供者（自动配置订阅）
proxy-providers:
  default:
    type: http
    url: "${SUBSCRIPTION_URL}"
    interval: 86400
    path: ./proxies/default.yaml
    health-check:
      enable: true
      interval: 600
      url: http://www.gstatic.com/generate_204

# 代理组
proxy-groups:
  - name: "PROXY"
    type: select
    use:
      - default
    proxies:
      - DIRECT

  - name: "AUTO"
    type: url-test
    use:
      - default
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

# 规则
rules:
  - DOMAIN-SUFFIX,local,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - IP-CIDR,100.64.0.0/10,DIRECT
  - DOMAIN-SUFFIX,cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF
    else
        cat > "$CLASH_CONFIG_DIR/config.yaml" << 'EOF'
# Clash配置文件
port: 7890
socks-port: 7891
redir-port: 7892
tproxy-port: 7893
mixed-port: 7890

# HTTP(S) and SOCKS5 server on the same port
allow-lan: true
bind-address: "*"
mode: rule
log-level: info
ipv6: false

# RESTful web API listening address
external-controller: 127.0.0.1:9090
secret: ""

# TUN配置
tun:
  enable: true
  stack: system
  device: clash-tun
  auto-route: true
  auto-detect-interface: true
  dns-hijack:
    - 8.8.8.8:53
    - 8.8.4.4:53

# DNS配置（针对国内网络环境优化）
dns:
  enable: true
  listen: 0.0.0.0:1053
  ipv6: false
  default-nameserver:
    - 223.5.5.5        # 阿里DNS
    - 223.6.6.6        # 阿里DNS备用
    - 114.114.114.114  # 114DNS
    - 119.29.29.29     # 腾讯DNS
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - "*.lan"
    - "*.local"
    - localhost.ptlogin2.qq.com
    - "+.srv.nintendo.net"
    - "+.stun.playstation.net"
    - "+.msftconnecttest.com"
    - "+.msftncsi.com"
  nameserver:
    - https://dns.alidns.com/dns-query    # 阿里DoH
    - https://doh.pub/dns-query           # 腾讯DoH
    - https://doh.360.cn/dns-query        # 360DoH
    - tls://dns.rubyfish.cn:853           # 红鱼DoT
  fallback:
    - https://1.1.1.1/dns-query          # CloudFlare
    - https://8.8.8.8/dns-query          # Google DNS
    - tls://8.8.4.4:853                  # Google DoT
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

# 代理提供者示例
proxy-providers:
  default:
    type: http
    # url: "your-subscription-url-here"
    interval: 86400
    path: ./proxies/default.yaml
    health-check:
      enable: true
      interval: 600
      url: http://www.gstatic.com/generate_204

# 代理组
proxy-groups:
  - name: "PROXY"
    type: select
    use:
      - default
    proxies:
      - DIRECT

  - name: "AUTO"
    type: url-test
    use:
      - default
    url: 'http://www.gstatic.com/generate_204'
    interval: 300

# 规则
rules:
  - DOMAIN-SUFFIX,local,DIRECT
  - IP-CIDR,127.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,17.0.0.0/8,DIRECT
  - IP-CIDR,100.64.0.0/10,DIRECT
  - DOMAIN-SUFFIX,cn,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
EOF
    fi

    chown "$CLASH_USER:$CLASH_USER" "$CLASH_CONFIG_DIR/config.yaml"
    chmod 644 "$CLASH_CONFIG_DIR/config.yaml"
    
    echo -e "${GREEN}配置文件创建完成${NC}"
}

# 创建systemd服务
create_systemd_service() {
    echo -e "${BLUE}创建systemd服务...${NC}"
    
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=Clash daemon, A rule-based proxy in Go.
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=$CLASH_HOME/clash -d $CLASH_CONFIG_DIR
ExecReload=/bin/kill -HUP \$MAINPID
User=$CLASH_USER
Group=$CLASH_USER
StandardOutput=journal
StandardError=journal
SyslogIdentifier=clash

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$CLASH_CONFIG_DIR $CLASH_LOG_DIR
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    echo -e "${GREEN}systemd服务创建完成${NC}"
}

# 配置系统代理
setup_system_proxy() {
    echo -e "${BLUE}配置系统代理...${NC}"
    
    # 创建代理配置脚本
    cat > "/usr/local/bin/clash-proxy-enable" << 'EOF'
#!/bin/bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
export NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16

# 应用到当前会话
echo "代理已启用:"
echo "HTTP Proxy: $http_proxy"
echo "HTTPS Proxy: $https_proxy"

# 写入profile以持久化
if ! grep -q "clash proxy" /etc/environment; then
    echo "# clash proxy settings" >> /etc/environment
    echo "http_proxy=http://127.0.0.1:7890" >> /etc/environment
    echo "https_proxy=http://127.0.0.1:7890" >> /etc/environment
    echo "HTTP_PROXY=http://127.0.0.1:7890" >> /etc/environment
    echo "HTTPS_PROXY=http://127.0.0.1:7890" >> /etc/environment
    echo "no_proxy=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16" >> /etc/environment
    echo "NO_PROXY=localhost,127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16" >> /etc/environment
fi
EOF

    cat > "/usr/local/bin/clash-proxy-disable" << 'EOF'
#!/bin/bash
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
unset no_proxy
unset NO_PROXY

echo "系统代理已禁用"

# 从environment文件中移除
sed -i '/# clash proxy/d' /etc/environment
sed -i '/http_proxy=/d' /etc/environment
sed -i '/https_proxy=/d' /etc/environment
sed -i '/HTTP_PROXY=/d' /etc/environment
sed -i '/HTTPS_PROXY=/d' /etc/environment
sed -i '/no_proxy=/d' /etc/environment
sed -i '/NO_PROXY=/d' /etc/environment
EOF

    chmod +x /usr/local/bin/clash-proxy-enable
    chmod +x /usr/local/bin/clash-proxy-disable
    
    echo -e "${GREEN}系统代理配置脚本创建完成${NC}"
    echo -e "${YELLOW}使用 'clash-proxy-enable' 启用系统代理${NC}"
    echo -e "${YELLOW}使用 'clash-proxy-disable' 禁用系统代理${NC}"
}

# 配置TUN模式
setup_tun_mode() {
    echo -e "${BLUE}配置TUN模式...${NC}"
    
    # 启用IP转发
    echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-clash.conf
    echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-clash.conf
    sysctl -p /etc/sysctl.d/99-clash.conf
    
    # 创建TUN管理脚本
    cat > "/usr/local/bin/clash-tun-enable" << 'EOF'
#!/bin/bash

# 检查TUN设备是否存在
if ! ip tuntap show | grep -q "clash-tun"; then
    echo "创建TUN设备..."
    ip tuntap add clash-tun mode tun user clash
    ip link set clash-tun up
fi

echo "TUN模式已启用"
echo "TUN设备: clash-tun"
EOF

    cat > "/usr/local/bin/clash-tun-disable" << 'EOF'
#!/bin/bash

if ip tuntap show | grep -q "clash-tun"; then
    echo "删除TUN设备..."
    ip link set clash-tun down
    ip tuntap del clash-tun mode tun
fi

echo "TUN模式已禁用"
EOF

    chmod +x /usr/local/bin/clash-tun-enable
    chmod +x /usr/local/bin/clash-tun-disable
    
    echo -e "${GREEN}TUN模式配置完成${NC}"
    echo -e "${YELLOW}使用 'clash-tun-enable' 启用TUN模式${NC}"
    echo -e "${YELLOW}使用 'clash-tun-disable' 禁用TUN模式${NC}"
}

# 创建管理脚本
create_management_script() {
    echo -e "${BLUE}创建Clash管理脚本...${NC}"
    
    cat > "/usr/local/bin/clash-ctl" << 'EOF'
#!/bin/bash

# Clash控制脚本

case "$1" in
    start)
        echo "启动Clash服务..."
        systemctl start clash
        ;;
    stop)
        echo "停止Clash服务..."
        systemctl stop clash
        ;;
    restart)
        echo "重启Clash服务..."
        systemctl restart clash
        ;;
    status)
        systemctl status clash
        ;;
    logs)
        journalctl -u clash -f
        ;;
    config)
        echo "编辑配置文件..."
        nano /etc/clash/config.yaml
        ;;
    reload)
        echo "重载配置..."
        systemctl reload clash
        ;;
    proxy-enable)
        clash-proxy-enable
        ;;
    proxy-disable)
        clash-proxy-disable
        ;;
    tun-enable)
        clash-tun-enable
        ;;
    tun-disable)
        clash-tun-disable
        ;;
    web)
        echo "Web面板: http://127.0.0.1:9090"
        echo "推荐使用clash-dashboard: http://clash.razord.top"
        ;;
    *)
        echo "使用方法: $0 {start|stop|restart|status|logs|config|reload|proxy-enable|proxy-disable|tun-enable|tun-disable|web}"
        echo ""
        echo "命令说明:"
        echo "  start         - 启动Clash服务"
        echo "  stop          - 停止Clash服务"
        echo "  restart       - 重启Clash服务"
        echo "  status        - 查看服务状态"
        echo "  logs          - 查看实时日志"
        echo "  config        - 编辑配置文件"
        echo "  reload        - 重载配置"
        echo "  proxy-enable  - 启用系统代理"
        echo "  proxy-disable - 禁用系统代理"
        echo "  tun-enable    - 启用TUN模式"
        echo "  tun-disable   - 禁用TUN模式"
        echo "  web           - 显示Web管理面板地址"
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/clash-ctl
    
    echo -e "${GREEN}管理脚本创建完成${NC}"
}

# 启动服务
start_service() {
    echo -e "${BLUE}启动Clash服务...${NC}"
    
    systemctl start "$SERVICE_NAME"
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}Clash服务启动成功${NC}"
    else
        echo -e "${RED}Clash服务启动失败${NC}"
        echo "请检查日志: journalctl -u clash"
        return 1
    fi
}

# 显示安装完成信息
show_completion_info() {
    echo -e "\n${GREEN}=== Clash安装完成 ===${NC}"
    
    # 检查是否已配置订阅
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SUBSCRIPTION_FILE="${SCRIPT_DIR}/ording-address"
    
    if [[ -f "$SUBSCRIPTION_FILE" ]]; then
        SUBSCRIPTION_URL=$(cat "$SUBSCRIPTION_FILE" | head -n 1 | tr -d '\r\n')
        echo -e "${GREEN}✅ 订阅地址已自动配置: ${SUBSCRIPTION_URL}${NC}"
        echo ""
    fi
    
    echo -e "${BLUE}服务管理:${NC}"
    echo "  启动: clash-ctl start"
    echo "  停止: clash-ctl stop"
    echo "  状态: clash-ctl status"
    echo "  日志: clash-ctl logs"
    echo ""
    echo -e "${BLUE}代理配置:${NC}"
    echo "  HTTP代理: 127.0.0.1:7890"
    echo "  SOCKS5代理: 127.0.0.1:7891"
    echo "  启用系统代理: clash-ctl proxy-enable"
    echo "  禁用系统代理: clash-ctl proxy-disable"
    echo ""
    echo -e "${BLUE}TUN模式:${NC}"
    echo "  启用TUN: clash-ctl tun-enable"
    echo "  禁用TUN: clash-ctl tun-disable"
    echo ""
    echo -e "${BLUE}Web管理:${NC}"
    echo "  访问地址: http://127.0.0.1:9090"
    echo "  推荐面板: http://clash.razord.top"
    echo ""
    echo -e "${BLUE}配置文件:${NC}"
    echo "  配置路径: $CLASH_CONFIG_DIR/config.yaml"
    echo "  编辑配置: clash-ctl config"
    echo ""
    
    if [[ -f "$SUBSCRIPTION_FILE" ]]; then
        echo -e "${GREEN}✅ 订阅配置已自动完成，可以直接开始使用！${NC}"
        echo -e "${BLUE}快速启动代理:${NC}"
        echo "  1. 启用系统代理: clash-ctl proxy-enable"
        echo "  2. 或启用TUN模式: clash-ctl tun-enable"
    else
        echo -e "${YELLOW}注意: 请编辑 $CLASH_CONFIG_DIR/config.yaml 添加您的代理订阅链接${NC}"
        echo -e "${YELLOW}或者在脚本目录创建 ording-address 文件，将订阅链接放入其中${NC}"
    fi
}

# 主函数
main() {
    echo -e "${GREEN}=== Linux Clash 安装脚本 ===${NC}"
    echo -e "${BLUE}支持Ubuntu无GUI环境，包含系统代理和TUN模式${NC}"
    echo ""
    
    check_root
    check_system
    install_dependencies
    create_user_and_dirs
    check_network_connectivity
    download_clash
    create_config
    create_systemd_service
    setup_system_proxy
    setup_tun_mode
    create_management_script
    start_service
    show_completion_info
    
    echo -e "\n${GREEN}安装完成！${NC}"
}

# 执行主函数
main "$@"
