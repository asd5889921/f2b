# Enhanced Fail2ban Manager / Fail2ban 增强管理器

[English](#english) | [中文说明](#中文说明)

## English

### 🚀 Quick Install
```bash
bash <(curl -s https://raw.githubusercontent.com/您的用户名/f2b/main/enhanced_f2b.sh)
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

---

## 中文说明

### 🚀 一键安装
```bash
bash <(curl -s https://raw.githubusercontent.com/您的用户名/f2b/main/enhanced_f2b.sh)
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

## 🔄 Update Log / 更新日志

### v1.0.0 (2024-03-14)
- Initial release / 首次发布
- Basic functions implementation / 基础功能实现
- Multi-system support / 多系统支持

## 📜 License
Apache 2.0

## 🤝 Contributing / 贡献
Feel free to open issues and pull requests / 欢迎提交问题和合并请求

## ⭐ Support / 支持
If you like this project, please give it a star / 如果您喜欢这个项目，请给它一个星标
