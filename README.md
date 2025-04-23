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

### 🔧 Supported Systems
- Debian
- Ubuntu
- CentOS
- RHEL
- Fedora

### 📦 Functions
1. Install/Reconfigure Fail2ban
2. View Fail2ban Status
3. Unban Specific IP
4. View Ban Logs
5. Auto-start on Boot

### ⚙️ Default Configuration
- Ban Time: 1 hour
- Find Time: 10 minutes
- Max Retry: 3 times
- Auto-ignore local network

### 📝 Notes
- Requires root privileges
- Automatically backs up existing configuration
- Supports automatic system log path recognition

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

### 🔧 支持的系统
- Debian
- Ubuntu
- CentOS
- RHEL
- Fedora

### 📦 功能列表
1. 安装/重新配置 Fail2ban
2. 查看 Fail2ban 状态
3. 解封指定 IP
4. 查看封禁日志
5. 开机自启动

### ⚙️ 默认配置
- 封禁时间：1小时
- 检测时间范围：10分钟
- 最大尝试次数：3次
- 自动忽略本地网络

### 📝 注意事项
- 需要 root 权限运行
- 自动备份现有配置
- 支持自动识别系统日志路径

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
ignoreip = 127.0.0.1/8 ::1

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

# 查看 SSH 封禁状态
sudo fail2ban-client status sshd

# 解封指定 IP
sudo fail2ban-client set sshd unbanip [IP地址]

# 查看日志
sudo tail -f /var/log/fail2ban.log

# 重启服务
sudo systemctl restart fail2ban
```

## 🔄 Update Log / 更新日志

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
