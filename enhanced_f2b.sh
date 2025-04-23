# 修改install_dependencies函数
install_dependencies() {
    log "${BLUE}检查基础依赖...${NC}"
    
    # 检查包管理器
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
        
        # Debian 12 需要特殊处理
        if [ "$OS" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
            $PKG_UPDATE
            $PKG_INSTALL fail2ban python3 python3-systemd iptables nftables || handle_error "安装失败"
        else
            $PKG_UPDATE
            $PKG_INSTALL fail2ban iptables || handle_error "安装失败"
        fi
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update || true"
        PKG_INSTALL="dnf install -y"
        $PKG_INSTALL epel-release
        $PKG_INSTALL fail2ban iptables || handle_error "安装失败"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update || true"
        PKG_INSTALL="yum install -y"
        $PKG_INSTALL epel-release
        $PKG_INSTALL fail2ban iptables || handle_error "安装失败"
    else
        handle_error "未找到支持的包管理器"
    fi
    
    log "${GREEN}基础依赖安装完成${NC}"
}

# 修改configure_fail2ban函数
configure_fail2ban() {
    log "${BLUE}配置Fail2ban...${NC}"
    
    # 创建配置目录
    mkdir -p /etc/fail2ban
    
    # 检测SSH端口
    local default_ssh_port=$(grep -oP '^Port\s+\K\d+' /etc/ssh/sshd_config 2>/dev/null || echo 22)
    echo -e "${YELLOW}检测到SSH端口为: $default_ssh_port${NC}"
    echo -e "${YELLOW}是否使用此端口？[Y/n]${NC} "
    read -r use_default_port
    
    if [[ "$use_default_port" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}请输入SSH端口：${NC}"
        read -r ssh_port
        if ! [[ "$ssh_port" =~ ^[0-9]+$ ]] || [ "$ssh_port" -lt 1 ] || [ "$ssh_port" -gt 65535 ]; then
            log "${RED}无效的端口号，使用默认端口 $default_ssh_port${NC}"
            ssh_port=$default_ssh_port
        fi
    else
        ssh_port=$default_ssh_port
    fi
    
    # 创建jail.local配置文件
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# 封禁时间（秒）
bantime = 3600
# 检测时间范围（秒）
findtime = 600
# 最大尝试次数
maxretry = 3
# 解封时间
unbantime = 3600
# 忽略IP
ignoreip = 127.0.0.1/8 ::1

# Debian 12 特殊配置
backend = systemd

# 动作设置
banaction = iptables-multiport
banaction_allports = iptables-allports

[sshd]
enabled = true
port = $ssh_port
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
EOF

    # 根据不同系统配置日志路径
    case $OS in
        debian|ubuntu)
            if [ "$OS" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
                # Debian 12 特殊配置
                mkdir -p /etc/systemd/system/fail2ban.service.d
                cat > /etc/systemd/system/fail2ban.service.d/override.conf << EOF
[Service]
ExecStartPre=/bin/mkdir -p /var/run/fail2ban
EOF
                systemctl daemon-reload
            fi
            sed -i 's|%(sshd_log)s|/var/log/auth.log|' /etc/fail2ban/jail.local
            ;;
        centos|rhel|fedora)
            sed -i 's|%(sshd_log)s|/var/log/secure|' /etc/fail2ban/jail.local
            ;;
    esac

    # 确保日志文件存在
    touch /var/log/fail2ban.log
    chmod 640 /var/log/fail2ban.log
}

# 修改install_fail2ban函数中的服务启动部分
install_fail2ban() {
    # ... 保持原有代码不变直到服务启动部分 ...
    
    # 确保服务目录存在
    mkdir -p /var/run/fail2ban
    chown -R root:root /var/run/fail2ban
    chmod 755 /var/run/fail2ban
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # 等待服务启动
    sleep 3
    
    if ! systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${RED}服务启动失败，尝试修复...${NC}"
        # 显示错误日志
        echo -e "${YELLOW}错误日志：${NC}"
        journalctl -u fail2ban -n 20 --no-pager
        
        # 尝试修复
        systemctl stop fail2ban
        rm -f /var/run/fail2ban/fail2ban.pid
        mkdir -p /var/run/fail2ban
        chown -R root:root /var/run/fail2ban
        chmod 755 /var/run/fail2ban
        systemctl daemon-reload
        systemctl restart fail2ban
        sleep 3
        
        if ! systemctl is-active fail2ban >/dev/null 2>&1; then
            echo -e "${RED}服务启动失败，请检查系统日志：${NC}"
            journalctl -u fail2ban -n 20 --no-pager
            handle_error "fail2ban服务未能正常启动"
        fi
    fi
    
    echo -e "\n${GREEN}Fail2ban 安装完成！${NC}"
    echo -e "${BLUE}当前状态：${NC}"
    sleep 1
    fail2ban-client status || echo -e "${RED}无法获取状态，请检查日志${NC}"
    
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}
