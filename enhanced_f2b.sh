# 修改configure_fail2ban函数
configure_fail2ban() {
    log "${BLUE}配置Fail2ban...${NC}"
    
    # 创建必要的目录
    mkdir -p /etc/fail2ban/filter.d
    mkdir -p /etc/fail2ban/action.d
    mkdir -p /var/run/fail2ban
    
    # 创建基础配置文件
    cat > /etc/fail2ban/fail2ban.conf << EOF
[Definition]
loglevel = INFO
logtarget = /var/log/fail2ban.log
syslogsocket = auto
socket = /var/run/fail2ban/fail2ban.sock
pidfile = /var/run/fail2ban/fail2ban.pid
dbfile = /var/lib/fail2ban/fail2ban.sqlite3
EOF

    # 创建sshd过滤器
    cat > /etc/fail2ban/filter.d/sshd.conf << EOF
[INCLUDES]
before = common.conf

[Definition]
_daemon = sshd

failregex = ^%(__prefix_line)s(?:error: PAM: )?Authentication failure for .* from <HOST>( via \S+)?\s*$
            ^%(__prefix_line)s(?:error: PAM: )?User not known from <HOST>\s*$
            ^%(__prefix_line)sFailed \S+ for invalid user .* from <HOST>( port \d*)?\s*$
            ^%(__prefix_line)sFailed \S+ for .* from <HOST>( port \d*)?\s*$
            ^%(__prefix_line)sROOT LOGIN REFUSED.* FROM <HOST>\s*$
            ^%(__prefix_line)s[iI](?:llegal|nvalid) user .* from <HOST>\s*$

ignoreregex =
EOF

    # 创建公共配置
    cat > /etc/fail2ban/filter.d/common.conf << EOF
[INCLUDES]

[Definition]

_daemon = \S+

__prefix_line = %(known/_daemon)s(?:\[\d+\])?: 

[Init]
known/_daemon = %(known/daemon)s
known/daemon = $_daemon
maxlines = 1
EOF

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
    cat > /etc/fail2ban/jail.conf << EOF
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

    # 创建jail.local（用户自定义配置）
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

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

    # 确保日志文件存在并设置权限
    touch /var/log/fail2ban.log
    chmod 640 /var/log/fail2ban.log
    
    # 设置目录权限
    chown -R root:root /etc/fail2ban
    chmod -R 644 /etc/fail2ban
    chmod 755 /etc/fail2ban
    chmod 755 /etc/fail2ban/filter.d
    chmod 755 /etc/fail2ban/action.d
    
    # 创建数据目录
    mkdir -p /var/lib/fail2ban
    chown -R root:root /var/lib/fail2ban
    chmod 755 /var/lib/fail2ban
}

# 修改install_fail2ban函数中的服务重启部分
install_fail2ban() {
    # ... 保持原有代码不变直到服务启动部分 ...
    
    # 确保服务目录存在并设置权限
    mkdir -p /var/run/fail2ban
    chown -R root:root /var/run/fail2ban
    chmod 755 /var/run/fail2ban
    
    # 停止现有服务
    systemctl stop fail2ban || true
    
    # 清理可能存在的锁定文件
    rm -f /var/run/fail2ban/fail2ban.pid
    rm -f /var/run/fail2ban/fail2ban.sock
    
    # 启动服务
    systemctl daemon-reload
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # 等待服务启动
    sleep 5
    
    if ! systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${RED}服务启动失败，尝试修复...${NC}"
        # 显示错误日志
        echo -e "${YELLOW}错误日志：${NC}"
        journalctl -u fail2ban -n 20 --no-pager
        
        # 尝试修复
        systemctl stop fail2ban
        rm -f /var/run/fail2ban/fail2ban.pid
        rm -f /var/run/fail2ban/fail2ban.sock
        mkdir -p /var/run/fail2ban
        chown -R root:root /var/run/fail2ban
        chmod 755 /var/run/fail2ban
        systemctl daemon-reload
        systemctl restart fail2ban
        sleep 5
        
        if ! systemctl is-active fail2ban >/dev/null 2>&1; then
            echo -e "${RED}服务启动失败，请检查系统日志：${NC}"
            journalctl -u fail2ban -n 20 --no-pager
            handle_error "fail2ban服务未能正常启动"
        fi
    fi
    
    echo -e "\n${GREEN}Fail2ban 安装完成！${NC}"
    echo -e "${BLUE}当前状态：${NC}"
    sleep 2
    fail2ban-client ping || echo -e "${RED}服务未响应${NC}"
    fail2ban-client status || echo -e "${RED}无法获取状态，请检查日志${NC}"
    
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}
