# Enhanced Fail2ban Manager / Fail2ban 增强管理器

[English](#english) | [中文说明](#中文说明)

## English

### 🚀 Quick Install
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

### 📋 Features
- Auto-detection of SSH port
- Multi-system support (Debian/Ubuntu/CentOS/RHEL/Fedora)
- Interactive configuration
- Automatic service management
- Real-time monitoring
- IP management tools
- Custom ban settings
- IP whitelist support
- Manual IP ban/unban

### 🔧 Supported Systems
- Debian
- Ubuntu
- CentOS
- RHEL
- Fedora

### 📦 Functions
1. Install/Reconfigure Fail2ban
2. Custom Configuration
3. View Fail2ban Status
4. View Current Banned IPs
5. Unban Specific IP
6. Manual IP Ban
7. View Ban Logs
8. Auto-start on Boot

### ⚙️ Customizable Settings
- SSH Port: Auto-detect or manual input
- Ban Time: Customizable (default: 1 hour)
- Find Time: Customizable (default: 10 minutes)
- Max Retry: Customizable (default: 3 times)
- IP Whitelist: Support multiple IPs
- Auto-ignore local network

### 📝 Notes
- Requires root privileges
- Automatically backs up existing configuration
- Supports automatic system log path recognition
- Supports custom IP ban/unban

### 💡 Alternative Installation Methods

1. One-line command:
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

2. Step by step installation:
```bash
# Download script
curl -sL -o f2b.sh https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh

# Add execution permission
chmod +x f2b.sh

# Run script
sudo ./f2b.sh
```

---

## 中文说明

### 🚀 一键安装
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

### 📋 特点
- 自动检测 SSH 端口
- 多系统支持（Debian/Ubuntu/CentOS/RHEL/Fedora）
- 交互式配置
- 自动服务管理
- 实时监控
- IP 管理工具
- 自定义封禁设置
- IP 白名单支持
- 手动封禁/解封 IP

### 🔧 支持的系统
- Debian
- Ubuntu
- CentOS
- RHEL
- Fedora

### 📦 功能列表
1. 安装/重新配置 Fail2ban
2. 自定义配置 Fail2ban
3. 查看 Fail2ban 状态
4. 查看当前封禁IP
5. 解封指定 IP
6. 手动封禁 IP
7. 查看封禁日志
8. 开机自启动

### ⚙️ 可自定义设置
- SSH 端口：自动检测或手动输入
- 封禁时间：可自定义（默认1小时）
- 检测时间范围：可自定义（默认10分钟）
- 最大尝试次数：可自定义（默认3次）
- IP白名单：支持添加多个IP
- 自动忽略本地网络

### 📝 注意事项
- 需要 root 权限运行
- 自动备份现有配置
- 支持自动识别系统日志路径
- 支持自定义封禁/解封IP

### 💡 其他安装方式

1. 一键命令安装：
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

2. 分步安装：
```bash
# 下载脚本
curl -sL -o f2b.sh https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh

# 添加执行权限
chmod +x f2b.sh

# 运行脚本
sudo ./f2b.sh
```

### 📚 配置文件示例

#### 1. Fail2ban 主配置文件 (/etc/fail2ban/jail.local)
```ini
[DEFAULT]
# 封禁时间（秒）
bantime = 3600
# 检测时间范围（秒）
findtime = 600
# 最大尝试次数
maxretry = 3
# 解封IP时间
unbantime = 3600
# 忽略的IP地址
ignoreip = 127.0.0.1/8 ::1 [您的白名单IP]

[sshd]
enabled = true
port = [您的SSH端口]
filter = sshd
logpath = /var/log/auth.log  # Debian/Ubuntu系统
# logpath = /var/log/secure  # CentOS/RHEL系统
maxretry = 3
```

### 🔧 常用命令
```bash
# 查看 Fail2ban 状态
sudo fail2ban-client status

# 查看当前封禁的IP列表
sudo fail2ban-client status sshd | grep "Banned IP list"

# 查看 SSH 封禁状态
sudo fail2ban-client status sshd

# 手动封禁 IP
sudo fail2ban-client set sshd banip [IP地址]

# 解封指定 IP
sudo fail2ban-client set sshd unbanip [IP地址]

# 查看日志
sudo tail -f /var/log/fail2ban.log

# 重启服务
sudo systemctl restart fail2ban
```

## 🔄 Update Log / 更新日志

### v1.1.1 (2024-03-15)
- Added dedicated banned IP list view / 添加独立的封禁IP列表查看功能
- Added remaining ban time display / 添加剩余封禁时间显示
- Improved menu structure / 优化菜单结构

### v1.1.0 (2024-03-15)
- Added custom ban settings / 添加自定义封禁设置
- Added IP whitelist support / 添加IP白名单支持
- Added manual IP ban feature / 添加手动封禁IP功能
- Enhanced configuration options / 增强配置选项

### v1.0.0 (2024-03-14)
- Initial release / 首次发布
- Basic functions implementation / 基础功能实现
- Multi-system support / 多系统支持

## 🛠 Troubleshooting / 故障排除

### 常见问题
1. 如果脚本无法运行，请检查：
   - 是否有 root 权限
   - 系统是否支持
   - 网络连接是否正常

2. 如果 Fail2ban 无法启动，请检查：
   - 系统日志路径是否正确
   - 服务状态：`systemctl status fail2ban`
   - 配置文件语法：`fail2ban-client -t`

3. 如果无法封禁 IP，请检查：
   - 防火墙规则
   - SELinux 状态
   - 日志文件权限

### 解决方案
1. 重置配置：
```bash
sudo rm /etc/fail2ban/jail.local
sudo ./f2b.sh
```

2. 查看详细日志：
```bash
sudo journalctl -u fail2ban -f
```

## 📜 License
Apache 2.0

## 🤝 Contributing / 贡献
Feel free to open issues and pull requests / 欢迎提交问题和合并请求

## ⭐ Support / 支持
If you like this project, please give it a star / 如果您喜欢这个项目，请给它一个星标 
