# Ubuntu Clash 安装故障排除指南

## 常见错误及解决方案

### 1. X11 显示错误

**错误信息：**
```
Missing X server or $DISPLAY
The platform failed to initialize. Exiting.
```

**原因：** Clash 尝试初始化GUI组件，但在无GUI的Ubuntu服务器上找不到显示服务器。

**解决方案：**
脚本已自动优化此问题，通过设置以下环境变量：
```bash
export DISPLAY=""
export XDG_RUNTIME_DIR=""
export QT_QPA_PLATFORM=offscreen
unset WAYLAND_DISPLAY
```

### 2. 段错误 (Segmentation fault)

**错误信息：**
```
Segmentation fault (core dumped)
```

**可能原因：**
1. 架构不匹配
2. 缺少运行时依赖
3. 文件损坏
4. 内存不足

**解决方案：**

#### A. 检查架构匹配
```bash
# 检查系统架构
uname -m

# 检查二进制文件架构
file /opt/clash/clash
```

确保架构匹配：
- x86_64 系统 → 使用 amd64 版本
- aarch64 系统 → 使用 arm64 版本

#### B. 安装运行时依赖
```bash
# 更新包列表
apt-get update

# 安装基础运行时库
apt-get install -y libc6 ca-certificates

# 安装额外C库（如果需要）
apt-get install -y libc6-dev gcc-multilib
```

#### C. 检查文件完整性
```bash
# 检查文件是否损坏
file /opt/clash/clash

# 检查ELF文件头
readelf -h /opt/clash/clash

# 检查依赖库
ldd /opt/clash/clash
```

### 3. 权限错误

**错误信息：**
```
Permission denied
```

**解决方案：**
```bash
# 修复文件权限
sudo chmod +x /opt/clash/clash
sudo chown clash:clash /opt/clash/clash

# 修复目录权限
sudo chown -R clash:clash /opt/clash
sudo chown -R clash:clash /etc/clash
```

### 4. 网络连接问题

**错误信息：**
```
connect: network is unreachable
```

**解决方案：**

#### A. 检查网络连接
```bash
# 测试基本网络
ping -c 3 8.8.8.8

# 测试DNS解析
nslookup google.com

# 测试HTTPS连接
curl -I https://www.google.com
```

#### B. 配置DNS
```bash
# 临时设置DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 永久设置DNS（systemd-resolved）
systemctl edit systemd-resolved
```

### 5. systemd 服务问题

**检查服务状态：**
```bash
# 查看服务状态
systemctl status clash

# 查看详细日志
journalctl -u clash -f

# 重启服务
systemctl restart clash
```

**常见服务错误：**

#### A. 服务启动失败
```bash
# 检查配置文件语法
/opt/clash/clash -t -d /etc/clash

# 检查端口占用
netstat -tlnp | grep :7890
```

#### B. 权限问题
```bash
# 检查服务用户
id clash

# 重新设置权限
sudo chown -R clash:clash /etc/clash
sudo chown -R clash:clash /var/log/clash
```

### 6. 内存不足

**症状：** 进程被意外终止，系统日志显示 OOM (Out of Memory)

**解决方案：**
```bash
# 检查内存使用
free -h

# 检查swap
swapon -s

# 添加swap（如果需要）
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

## 完整的故障诊断流程

### 1. 运行诊断命令
```bash
# 下载并运行诊断脚本
cd /path/to/clash-install
bash debug-install.sh
```

### 2. 手动验证安装
```bash
# 检查文件存在
ls -la /opt/clash/clash

# 检查权限
stat /opt/clash/clash

# 尝试运行
sudo -u clash /opt/clash/clash -v
```

### 3. 检查系统环境
```bash
# 检查系统信息
uname -a
cat /etc/os-release

# 检查已安装的包
dpkg -l | grep -E "(libc6|ca-certificates)"

# 检查环境变量
env | grep -E "(DISPLAY|XDG_RUNTIME_DIR)"
```

### 4. 测试网络功能
```bash
# 启动服务
systemctl start clash

# 检查端口监听
netstat -tlnp | grep clash

# 测试代理
curl -x http://127.0.0.1:7890 http://www.google.com
```

## 预防措施

### 1. 系统要求确认
- Ubuntu 18.04+ 或其他 Debian 系发行版
- 至少 512MB 可用内存
- 至少 100MB 可用磁盘空间
- systemd 支持

### 2. 架构确认
```bash
# 在下载前确认架构
uname -m

# 下载对应版本
# x86_64 → mihomo-linux-amd64-*.gz
# aarch64 → mihomo-linux-arm64-*.gz
```

### 3. 网络环境
- 确保服务器可以访问互联网
- 如果在防火墙后，确保必要端口开放
- 配置正确的DNS服务器

## 获取支持

如果问题仍然存在：

1. **收集日志信息：**
   ```bash
   journalctl -u clash --no-pager > clash.log
   dmesg | tail -n 50 > system.log
   ```

2. **检查系统状态：**
   ```bash
   systemctl status clash > status.log
   free -h > memory.log
   ```

3. **提供以下信息：**
   - Ubuntu 版本 (`cat /etc/os-release`)
   - 系统架构 (`uname -m`)
   - 错误日志
   - 使用的二进制文件版本

## 更新日志

- **2024-12-19**: 添加 X11 错误处理和环境优化
- **2024-12-19**: 改进架构检测和验证逻辑
- **2024-12-19**: 添加依赖库安装和故障诊断
