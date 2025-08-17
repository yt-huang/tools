#!/usr/bin/env bash

# 下载源速度测试脚本
# 用于测试各个 mihomo 下载源的可用性和速度

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
VERSION="1.18.8"
ARCH="amd64"
TEST_SIZE_LIMIT="10MB"  # 测试下载的大小限制
TIMEOUT=30              # 连接超时时间

# 测试结果数组
declare -a TEST_RESULTS

echo -e "${BLUE}开始测试 mihomo v${VERSION} 各下载源速度...${NC}\n"

# 下载源列表 (兼容旧版 bash)
SOURCES=(
    "JSDelivr CDN|https://cdn.jsdelivr.net/gh/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "ghp.ci 极速代理|https://ghp.ci/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "moeyy.xyz 极速代理|https://github.moeyy.xyz/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "fgit.ml 国内镜像|https://hub.fgit.ml/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "fastgit.org 国内镜像|https://download.fastgit.org/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "ghproxy.com 代理|https://ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "mirror.ghproxy.com 代理|https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
    "GitHub 官方源|https://github.com/MetaCubeX/mihomo/releases/download/v${VERSION}/mihomo-linux-${ARCH}-v${VERSION}.gz"
)

# 测试单个下载源
test_download_source() {
    local source_name="$1"
    local url="$2"
    local test_file="/tmp/mihomo_test_$$"
    
    echo -e "${YELLOW}测试: ${source_name}${NC}"
    echo -e "URL: $url"
    
    # 使用 curl 测试下载速度和连接性
    local start_time=$(date +%s.%N 2>/dev/null || date +%s)
    
    # 只下载前 10MB 来测试速度，避免浪费流量
    if curl -L --connect-timeout $TIMEOUT --max-time $((TIMEOUT*2)) \
            --range 0-10485760 \
            --progress-bar \
            -o "$test_file" \
            "$url" 2>/dev/null; then
        
        local end_time=$(date +%s.%N 2>/dev/null || date +%s)
        if command -v bc >/dev/null 2>&1; then
            local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1")
        else
            local duration=$(( end_time - start_time ))
        fi
        
        # macOS 和 Linux 兼容的文件大小获取
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local file_size=$(stat -f%z "$test_file" 2>/dev/null || echo "0")
        else
            local file_size=$(stat -c%s "$test_file" 2>/dev/null || echo "0")
        fi
        
        if [ "$file_size" -gt 0 ]; then
            # 计算速度 (兼容 macOS)
            if command -v bc >/dev/null 2>&1; then
                local speed_mbps=$(echo "scale=2; ($file_size * 8) / ($duration * 1000000)" | bc -l 2>/dev/null || echo "0.00")
            else
                # 简单的整数计算作为备选
                local speed_mbps=$(( file_size * 8 / 1000000 ))
            fi
            printf "${GREEN}✓ 成功 - 用时: %.2fs, 速度: %s Mbps${NC}\n" "$duration" "$speed_mbps"
            TEST_RESULTS+=("$source_name|SUCCESS|$duration|$speed_mbps")
        else
            echo -e "${RED}✗ 失败 - 下载文件为空${NC}"
            TEST_RESULTS+=("$source_name|FAILED|N/A|N/A")
        fi
        
        # 清理测试文件
        rm -f "$test_file"
    else
        echo -e "${RED}✗ 失败 - 连接超时或无法访问${NC}"
        TEST_RESULTS+=("$source_name|FAILED|N/A|N/A")
    fi
    
    echo ""
}

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查系统依赖...${NC}"
    
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}错误: 未找到 curl 命令，请先安装 curl${NC}"
        exit 1
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        echo -e "${YELLOW}警告: 未找到 bc 命令，安装以获得更精确的速度计算${NC}"
        echo "Ubuntu/Debian: sudo apt install bc"
        echo "CentOS/RHEL: sudo yum install bc"
        echo ""
    fi
}

# 显示测试结果摘要
show_results_summary() {
    echo -e "\n${BLUE}==================== 测试结果摘要 ====================${NC}\n"
    
    printf "%-25s %-10s %-12s %-10s\n" "下载源" "状态" "用时(秒)" "速度(Mbps)"
    echo "--------------------------------------------------------"
    
    # 按速度排序显示结果
    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r name status duration speed <<< "$result"
        
        if [ "$status" = "SUCCESS" ]; then
            printf "%-25s ${GREEN}%-10s${NC} %-12s %-10s\n" "$name" "$status" "$duration" "$speed"
        else
            printf "%-25s ${RED}%-10s${NC} %-12s %-10s\n" "$name" "$status" "$duration" "$speed"
        fi
    done
    
    echo ""
    
    # 推荐最快的源
    local best_source=""
    local best_speed="0"
    
    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r name status duration speed <<< "$result"
        if [ "$status" = "SUCCESS" ] && [ "$speed" != "N/A" ]; then
            # 简单的数值比较 (兼容性)
            if command -v bc >/dev/null 2>&1; then
                if (( $(echo "$speed > $best_speed" | bc -l 2>/dev/null || echo "0") )); then
                    best_speed=$speed
                    best_source=$name
                fi
            else
                # 整数比较作为备选
                if [ "${speed%.*}" -gt "${best_speed%.*}" ] 2>/dev/null; then
                    best_speed=$speed
                    best_source=$name
                fi
            fi
        fi
    done
    
    if [ -n "$best_source" ]; then
        echo -e "${GREEN}🚀 推荐使用: $best_source (速度: ${best_speed} Mbps)${NC}"
    else
        echo -e "${RED}⚠️  所有源都无法正常访问，请检查网络连接${NC}"
    fi
}

# 主函数
main() {
    check_dependencies
    
    echo -e "${BLUE}开始并发测试所有下载源...${NC}\n"
    
    # 并发测试所有源以节省时间
    for source in "${SOURCES[@]}"; do
        IFS='|' read -r name url <<< "$source"
        test_download_source "$name" "$url" &
    done
    
    # 等待所有后台任务完成
    wait
    
    show_results_summary
    
    echo -e "\n${BLUE}测试完成！${NC}"
    echo -e "${YELLOW}提示: 您可以根据测试结果修改 download-sources.yaml 中的源优先级${NC}"
}

# 执行主函数
main "$@"
