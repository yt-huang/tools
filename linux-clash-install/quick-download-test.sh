#!/usr/bin/env bash

# 快速下载测试脚本 - 测试最佳下载源

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="1.18.8"
ARCH="amd64"

echo -e "${BLUE}快速测试 mihomo v${VERSION} 最佳下载源...${NC}\n"

# 最优下载源列表 (基于测试结果排序)
BEST_SOURCES=(
    "GitHub 官方源|https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "ghproxy.com 代理|https://ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "mirror.ghproxy.com 代理|https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "gh.api.99988866.xyz 代理|https://gh.api.99988866.xyz/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
)

# 快速测试函数
quick_test() {
    local name="$1"
    local url="$2"
    
    echo -e "${YELLOW}测试: ${name}${NC}"
    
    # 只测试连接性和响应时间
    if curl -I --connect-timeout 10 --max-time 15 "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 可用${NC}"
        return 0
    else
        echo -e "${RED}✗ 不可用${NC}"
        return 1
    fi
}

# 实际下载测试
download_test() {
    local name="$1"
    local url="$2"
    local output_file="mihomo-linux-${ARCH}-v${VERSION}.gz"
    
    echo -e "\n${BLUE}使用 ${name} 开始下载...${NC}"
    echo -e "下载地址: ${url}"
    
    if curl -L --progress-bar \
            --connect-timeout 30 \
            --max-time 300 \
            -o "$output_file" \
            "$url"; then
        
        local file_size=$(ls -lh "$output_file" | awk '{print $5}')
        echo -e "${GREEN}✓ 下载成功！文件大小: ${file_size}${NC}"
        echo -e "文件保存为: ${output_file}"
        return 0
    else
        echo -e "${RED}✗ 下载失败${NC}"
        rm -f "$output_file"
        return 1
    fi
}

# 主函数
main() {
    local working_source=""
    
    echo -e "${BLUE}第一步: 快速测试源可用性...${NC}\n"
    
    # 快速测试所有源
    for source in "${BEST_SOURCES[@]}"; do
        IFS='|' read -r name url <<< "$source"
        if quick_test "$name" "$url"; then
            if [ -z "$working_source" ]; then
                working_source="$name|$url"
            fi
        fi
        echo ""
    done
    
    if [ -z "$working_source" ]; then
        echo -e "${RED}❌ 所有下载源都不可用，请检查网络连接${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}第二步: 使用最快的可用源下载...${NC}"
    
    IFS='|' read -r best_name best_url <<< "$working_source"
    
    if download_test "$best_name" "$best_url"; then
        echo -e "\n${GREEN}🎉 下载完成！${NC}"
        echo -e "${YELLOW}提示: 您可以使用以下命令解压并安装:${NC}"
        echo -e "  gunzip mihomo-linux-${ARCH}-v${VERSION}.gz"
        echo -e "  chmod +x mihomo-linux-${ARCH}-v${VERSION}"
        echo -e "  sudo mv mihomo-linux-${ARCH}-v${VERSION} /usr/local/bin/mihomo"
    else
        echo -e "\n${RED}❌ 下载失败，尝试其他源...${NC}"
        
        # 尝试其他源
        for source in "${BEST_SOURCES[@]}"; do
            IFS='|' read -r name url <<< "$source"
            if [ "$name|$url" != "$working_source" ]; then
                echo -e "\n${YELLOW}尝试: ${name}${NC}"
                if download_test "$name" "$url"; then
                    echo -e "\n${GREEN}🎉 下载完成！${NC}"
                    exit 0
                fi
            fi
        done
        
        echo -e "\n${RED}❌ 所有源都下载失败${NC}"
        exit 1
    fi
}

# 执行主函数
main "$@"
