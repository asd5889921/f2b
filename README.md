# Fail2ban 增强版管理器

[中文](#中文说明) | [English](#english-description)

## 中文说明

### 目录
- [快速安装](#快速安装)
- [功能特点](#功能特点)
- [系统要求](#系统要求)
- [主要功能](#主要功能)
- [快捷命令](#快捷命令)
- [配置说明](#配置说明)
- [注意事项](#注意事项)
- [问题排查](#问题排查)
- [更新日志](#更新日志)

### 快速安装
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

### 功能特点
- ✨ 一键安装/配置
- 🔒 智能SSH端口检测
- 🚫 IP封禁管理
- 📊 实时状态监控
- 🔄 自动服务修复
- 💻 便捷的命令行工具

### 系统要求
- Debian/Ubuntu 系统
- 需要root权限
- 系统支持systemd服务管理

### 主要功能
1. 安装/重新配置 Fail2ban
2. 查看服务运行状态
3. 管理封禁IP
4. 查看封禁日志
5. 修改配置参数
6. 服务管理
7. 完整卸载功能

### 快捷命令
安装完成后，可以使用以下命令：
```bash
f2b status   # 查看状态
f2b banned   # 查看封禁IP
f2b unban IP # 解封指定IP
f2b ban IP   # 手动封禁IP
f2b log      # 查看日志
```

### 配置说明
- 默认封禁时间：3600秒（1小时）
- 检测时间范围：600秒（10分钟）
- 最大尝试次数：3次
- 自动解封时间：3600秒（1小时）

### 注意事项
1. 首次安装会自动备份原有配置
2. 建议安装前先更新系统
3. 脚本会自动安装所需依赖
4. 支持自动识别系统类型

### 问题排查
如果遇到问题，请检查：
1. 系统日志: `/var/log/fail2ban.log`
2. 服务状态: `systemctl status fail2ban`
3. 认证日志: `/var/log/auth.log`

### 更新日志

#### v1.2.1
- 添加卸载功能
- 优化SSH端口配置
- 修复服务启动问题
- 改进错误处理机制

---

## English Description

### Table of Contents
- [Quick Install](#quick-install)
- [Features](#features)
- [Requirements](#requirements)
- [Main Functions](#main-functions)
- [Quick Commands](#quick-commands)
- [Configuration](#configuration)
- [Notes](#notes)
- [Troubleshooting](#troubleshooting)
- [Changelog](#changelog)

### Quick Install
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

### Features
- ✨ One-click installation
- 🔒 Smart SSH port detection
- 🚫 IP ban management
- 📊 Real-time status monitoring
- 🔄 Automatic service repair
- 💻 Convenient CLI tools

### Requirements
- Debian/Ubuntu system
- Root privileges required
- System with systemd support

### Main Functions
1. Install/Reconfigure Fail2ban
2. View service status
3. Manage banned IPs
4. View ban logs
5. Modify configurations
6. Service management
7. Complete uninstall

### Quick Commands
After installation, you can use:
```bash
f2b status   # Check status
f2b banned   # View banned IPs
f2b unban IP # Unban IP
f2b ban IP   # Ban IP
f2b log      # View logs
```

### Configuration
- Default ban time: 3600s (1 hour)
- Find time: 600s (10 minutes)
- Max retry: 3 times
- Unban time: 3600s (1 hour)

### Notes
1. Original config will be backed up
2. System update recommended before install
3. Script will install necessary dependencies
4. Automatic system detection

### Troubleshooting
If issues occur, check:
1. System log: `/var/log/fail2ban.log`
2. Service status: `systemctl status fail2ban`
3. Auth log: `/var/log/auth.log`

### Changelog

#### v1.2.1
- Added uninstall feature
- Optimized SSH port configuration
- Fixed service startup issues
- Improved error handling

## License

MIT License - See [LICENSE](LICENSE) file for details

## Author

- GitHub: [@asd5889921](https://github.com/asd5889921)

## 功能特点

- 🚀 一键安装和交互式配置
- 🛡️ 简单高效的SSH防护
- 🔄 自动备份现有配置
- 📝 详细的安装日志
- 🌐 支持多种Linux发行版
- 🔧 便捷的管理界面
- 📊 实时监控和管理

## 快速开始

### 一键安装

```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
```

### 手动安装

1. 克隆仓库：
```bash
git clone https://github.com/asd5889921/f2b.git
```

2. 进入目录：
```bash
cd f2b
```

3. 添加执行权限：
```bash
chmod +x enhanced_f2b.sh
```

4. 运行脚本：
```bash
sudo ./enhanced_f2b.sh
```

## 支持的系统

- Debian 8+
- Ubuntu 16.04+
- CentOS 7+
- RHEL 7+
- Fedora 30+

## 交互式功能

### 主菜单选项
1. 安装/重新配置 Fail2ban
2. 查看 Fail2ban 状态
3. 查看当前封禁IP
4. 解封指定IP
5. 手动封禁IP
6. 查看封禁日志
7. 修改配置
8. 重启服务
9. 卸载 Fail2ban
0. 退出

### 配置选项
- 修改封禁时间
- 修改最大尝试次数
- 修改检测时间范围
- 添加IP白名单

### 快捷命令
安装完成后，可以使用以下命令快速管理：

- `f2b status` - 查看Fail2ban状态
- `f2b banned` - 查看被封禁的IP
- `f2b ban <IP>` - 手动封禁IP
- `f2b unban <IP>` - 解封IP
- `f2b log` - 查看日志

## 配置说明

### 默认配置
- 封禁时间：3600秒（1小时）
- 检测时间范围：600秒（10分钟）
- 最大尝试次数：3次
- 自动解封时间：3600秒（1小时）

### 配置文件位置
- 主配置文件：`/etc/fail2ban/jail.local`
- 日志文件：`/var/log/fail2ban.log`
- 安装日志：`/var/log/fail2ban_install.log`

## 使用示例

### 1. 安装和初始配置
```bash
bash <(curl -sL https://raw.githubusercontent.com/asd5889921/f2b/main/enhanced_f2b.sh)
# 选择选项 1 进行安装
```

### 2. 查看当前状态
```bash
# 通过菜单：
./enhanced_f2b.sh  # 选择选项 2

# 或使用快捷命令：
f2b status
```

### 3. 管理封禁IP
```bash
# 查看封禁列表：
f2b banned

# 手动封禁IP：
f2b ban 192.168.1.100

# 解封IP：
f2b unban 192.168.1.100
```

### 4. 卸载 Fail2ban
```bash
# 通过菜单：
./enhanced_f2b.sh  # 选择选项 9

# 或直接运行卸载命令：
f2b uninstall  # 将在下个版本添加
```

## 故障排除

如果遇到问题，可以：

1. 检查安装日志：
```bash
cat /var/log/fail2ban_install.log
```

2. 查看Fail2ban状态：
```bash
f2b status
```

3. 查看系统日志：
```bash
journalctl -u fail2ban
```

## 注意事项

1. 脚本需要root权限运行
2. 会自动备份现有配置
3. 支持自动识别系统类型
4. 仅安装必要的依赖（fail2ban和iptables）

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目！

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 作者

- GitHub: [@asd5889921](https://github.com/asd5889921)

## 更新日志

### v1.2.0
- 添加交互式菜单界面
- 精简依赖，提高安装速度
- 优化配置管理功能
- 增加快捷命令支持
- 改进错误处理机制

### v1.2.1
- 添加卸载功能
- 优化SSH端口配置
- 修复服务启动问题
- 改进错误处理机制

## 致谢

感谢所有为这个项目做出贡献的开发者！ 
