# ... existing code ...

### 📦 Functions
1. Install/Reconfigure Fail2ban
2. Custom Configuration
3. View Fail2ban Status
4. View Current Banned IPs
5. Unban Specific IP
6. Manual IP Ban
7. View Ban Logs
8. Auto-start on Boot

// ... existing code ...

### 📦 功能列表
1. 安装/重新配置 Fail2ban
2. 自定义配置 Fail2ban
3. 查看 Fail2ban 状态
4. 查看当前封禁IP
5. 解封指定 IP
6. 手动封禁 IP
7. 查看封禁日志
8. 开机自启动

// ... existing code ...

### 🔧 常用命令
```bash
# 查看 Fail2ban 状态
sudo fail2ban-client status

# 查看当前封禁的IP列表
sudo fail2ban-client get sshd banned

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

// ... existing code ...
