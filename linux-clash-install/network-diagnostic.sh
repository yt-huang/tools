#!/bin/bash

# 网络连接诊断脚本
# 用于排查 Clash 安装过程中的网络问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Clash 网络连接诊断工具 ===${NC}"
echo -e "${BLUE}诊断网络连接问题，帮助解决下载失败${NC}"
echo ""

# 检查基本网络连接
echo -e "${BLUE}1. 检查基本网络连接...${NC}"
if ping -c 3 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ 网络连接正常${NC}"
else
    echo -e "${RED}✗ 网络连接失败${NC}"
    echo -e "${YELLOW}建议检查网络配置或联系网络管理员${NC}"
fi

# 检查DNS解析
echo -e "\n${BLUE}2. 检查DNS解析...${NC}"
test_domains=("github.com" "cdn.jsdelivr.net" "www.google.com")

for domain in "${test_domains[@]}"; do
    if nslookup "$domain" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $domain 解析正常${NC}"
    else
        echo -e "${RED}✗ $domain 解析失败${NC}"
    fi
done

# 测试不同DNS服务器
echo -e "\n${BLUE}3. 测试不同DNS服务器...${NC}"
dns_servers=("8.8.8.8" "1.1.1.1" "223.5.5.5" "114.114.114.114")

for dns in "${dns_servers[@]}"; do
    if nslookup github.com "$dns" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS $dns 可用${NC}"
    else
        echo -e "${RED}✗ DNS $dns 不可用${NC}"
    fi
done

# 检查HTTPS连接
echo -e "\n${BLUE}4. 检查HTTPS连接...${NC}"
test_urls=(
    "https://github.com"
    "https://cdn.jsdelivr.net"
    "https://api.github.com"
)

for url in "${test_urls[@]}"; do
    if curl -s --connect-timeout 10 --max-time 30 "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $url 连接成功${NC}"
    else
        echo -e "${RED}✗ $url 连接失败${NC}"
    fi
done

# 测试下载速度
echo -e "\n${BLUE}5. 测试下载速度...${NC}"
echo "正在从不同源测试下载速度..."

# 创建临时目录
TEMP_DIR="/tmp/clash-speed-test"
mkdir -p "$TEMP_DIR"

# 测试文件列表
test_files=(
    "https://cdn.jsdelivr.net/gh/Dreamacro/clash@v1.18.0/README.md jsdelivr_cdn"
    "https://github.com/Dreamacro/clash/raw/master/README.md github_direct"
    "https://ghproxy.com/https://github.com/Dreamacro/clash/raw/master/README.md github_proxy"
)

for test_file in "${test_files[@]}"; do
    url=$(echo "$test_file" | cut -d' ' -f1)
    name=$(echo "$test_file" | cut -d' ' -f2)
    
    echo -n "测试 $name: "
    
    start_time=$(date +%s.%N)
    if wget --timeout=30 --tries=1 -q -O "$TEMP_DIR/test_$name" "$url" 2>/dev/null; then
        end_time=$(date +%s.%N)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        echo -e "${GREEN}成功 (${duration}s)${NC}"
    else
        echo -e "${RED}失败${NC}"
    fi
done

# 清理测试文件
rm -rf "$TEMP_DIR"

# 检查系统时间
echo -e "\n${BLUE}6. 检查系统时间...${NC}"
current_time=$(date)
echo "当前系统时间: $current_time"

# 获取网络时间进行比较
if command -v ntpdate >/dev/null 2>&1; then
    echo "正在同步网络时间..."
    if ntpdate -q pool.ntp.org >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 系统时间同步正常${NC}"
    else
        echo -e "${YELLOW}! 建议手动同步系统时间${NC}"
    fi
else
    echo -e "${YELLOW}! ntpdate 未安装，无法检查时间同步${NC}"
fi

# 检查防火墙状态
echo -e "\n${BLUE}7. 检查防火墙状态...${NC}"
if command -v ufw >/dev/null 2>&1; then
    ufw_status=$(ufw status 2>/dev/null | head -1)
    echo "UFW状态: $ufw_status"
elif command -v iptables >/dev/null 2>&1; then
    iptables_rules=$(iptables -L | wc -l)
    echo "iptables规则数: $iptables_rules"
fi

# 检查代理环境变量
echo -e "\n${BLUE}8. 检查代理环境变量...${NC}"
proxy_vars=("http_proxy" "https_proxy" "HTTP_PROXY" "HTTPS_PROXY")
proxy_found=false

for var in "${proxy_vars[@]}"; do
    if [[ -n "${!var}" ]]; then
        echo "$var = ${!var}"
        proxy_found=true
    fi
done

if [[ "$proxy_found" == false ]]; then
    echo "未检测到代理环境变量"
fi

# 提供解决建议
echo -e "\n${GREEN}=== 诊断完成 ===${NC}"
echo -e "${BLUE}如果遇到下载问题，建议尝试以下解决方案：${NC}"
echo ""
echo "1. 如果DNS解析失败："
echo "   sudo echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
echo ""
echo "2. 如果需要使用代理："
echo "   export http_proxy=http://your-proxy:port"
echo "   export https_proxy=http://your-proxy:port"
echo ""
echo "3. 如果系统时间不正确："
echo "   sudo ntpdate pool.ntp.org"
echo ""
echo "4. 如果防火墙阻止连接："
echo "   sudo ufw allow out 80,443/tcp"
echo ""
echo "5. 手动下载Clash："
echo "   访问 https://github.com/Dreamacro/clash/releases"
echo "   或者 https://cdn.jsdelivr.net/gh/Dreamacro/clash/releases/"

echo -e "\n${YELLOW}诊断日志已保存，可用于故障排查${NC}"
