# Enhanced Fail2ban 安装脚本

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)

## 功能特点

- 🚀 一键安装和配置 Fail2ban
- 🛡️ 增强的SSH防护规则
- 🔄 自动备份现有配置
- 📝 详细的安装日志
- 🌐 支持多种Linux发行版
- 🔧 自动配置防火墙规则
- 🔒 自动处理SELinux策略
- 📊 便捷的管理命令

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

## 主要功能

### 自动安装和配置
- 自动检测系统类型
- 安装必要依赖
- 配置Fail2ban服务
- 设置开机自启
- 配置日志轮转

### 安全特性
- 备份现有配置
- 增强的SSH防护规则
- 自动配置防火墙
- SELinux策略适配
- 详细的安装日志

### 便捷管理命令
安装完成后，可以使用以下命令管理Fail2ban：

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

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目！

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 作者

- GitHub: [@asd5889921](https://github.com/asd5889921)

## 更新日志

### v1.2.0
- 增加了自动备份功能
- 改进了错误处理机制
- 添加了详细的日志记录
- 优化了系统兼容性
- 增强了SSH防护规则

## 致谢

感谢所有为这个项目做出贡献的开发者！
