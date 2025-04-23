# 在show_menu函数中添加卸载选项
show_menu() {
    clear
    echo -e "${GREEN}=== Fail2ban 增强版管理器 v${VERSION} ===${NC}"
    echo -e "${BLUE}1.${NC} 安装/重新配置 Fail2ban"
    echo -e "${BLUE}2.${NC} 查看 Fail2ban 状态"
    echo -e "${BLUE}3.${NC} 查看当前封禁IP"
    echo -e "${BLUE}4.${NC} 解封指定IP"
    echo -e "${BLUE}5.${NC} 手动封禁IP"
    echo -e "${BLUE}6.${NC} 查看封禁日志"
    echo -e "${BLUE}7.${NC} 修改配置"
    echo -e "${BLUE}8.${NC} 重启服务"
    echo -e "${RED}9.${NC} 卸载 Fail2ban"
    echo -e "${BLUE}0.${NC} 退出"
    echo
    echo -e "${YELLOW}请输入选项 [0-9]:${NC} "
}

# 添加卸载函数
uninstall_fail2ban() {
    clear
    echo -e "${RED}=== 卸载 Fail2ban ===${NC}"
    echo -e "${YELLOW}警告：这将完全删除 Fail2ban 及其配置${NC}"
    echo -e "${YELLOW}是否继续？[y/N]${NC} "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 停止服务
        systemctl stop fail2ban
        systemctl disable fail2ban
        
        # 删除配置文件
        rm -rf /etc/fail2ban
        rm -f /usr/local/bin/f2b
        
        # 卸载软件包
        case $OS in
            debian|ubuntu)
                $PKG_INSTALL remove --purge fail2ban
                ;;
            centos|rhel|fedora)
                $PKG_INSTALL remove fail2ban
                ;;
        esac
        
        echo -e "${GREEN}Fail2ban 已完全卸载${NC}"
        sleep 2
        exit 0
    else
        echo -e "${BLUE}取消卸载${NC}"
        sleep 1
    fi
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

# 动作设置
banaction = iptables-multiport

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
            sed -i 's|%(sshd_log)s|/var/log/auth.log|' /etc/fail2ban/jail.local
            ;;
        centos|rhel|fedora)
            sed -i 's|%(sshd_log)s|/var/log/secure|' /etc/fail2ban/jail.local
            ;;
    esac
}

# 修改install_fail2ban函数
install_fail2ban() {
    clear
    echo -e "${GREEN}=== 开始安装 Fail2ban ===${NC}"
    
    check_root
    init_log
    create_backup
    get_system_info
    install_dependencies
    configure_fail2ban
    create_shortcuts
    
    # 确保服务目录存在
    mkdir -p /var/run/fail2ban
    
    # 启动服务
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # 等待服务启动
    sleep 2
    
    if ! systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${RED}服务启动失败，尝试修复...${NC}"
        # 尝试修复
        mkdir -p /var/run/fail2ban
        chown -R root:root /var/run/fail2ban
        systemctl restart fail2ban
        sleep 2
        
        if ! systemctl is-active fail2ban >/dev/null 2>&1; then
            handle_error "fail2ban服务未能正常启动，请检查日志: journalctl -u fail2ban"
        fi
    fi
    
    echo -e "\n${GREEN}Fail2ban 安装完成！${NC}"
    echo -e "${BLUE}当前状态：${NC}"
    sleep 1  # 给服务一点启动时间
    fail2ban-client status
    
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 在main函数中添加卸载选项
main() {
    while true; do
        show_menu
        read -r choice
        case $choice in
            1) install_fail2ban ;;
            2) show_status ;;
            3) show_banned ;;
            4) unban_ip ;;
            5) ban_ip ;;
            6) show_log ;;
            7) edit_config ;;
            8) restart_service ;;
            9) uninstall_fail2ban ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选项${NC}" ; sleep 1 ;;
        esac
    done
}
