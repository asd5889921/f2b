# ... existing code ...

# 显示封禁IP列表
show_banned_ips() {
    echo -e "${BLUE}当前封禁的IP列表：${NC}"
    local banned_ips=$(fail2ban-client get sshd banned)
    if [ -z "$banned_ips" ]; then
        echo -e "${YELLOW}当前没有被封禁的IP${NC}"
    else
        echo -e "${YELLOW}$banned_ips${NC}"
        echo -e "\n${BLUE}封禁详情：${NC}"
        for ip in $banned_ips; do
            local remaining_time=$(fail2ban-client get sshd bantime $ip)
            echo -e "IP: ${YELLOW}$ip${NC}"
            echo -e "剩余封禁时间: ${YELLOW}$((remaining_time/60))分钟${NC}"
            echo "----------------------------------------"
        done
    fi
}

# 主菜单
main_menu() {
    while true; do
        echo -e "\n${GREEN}=== Fail2ban 管理脚本 v${VERSION} ===${NC}"
        echo -e "${BLUE}1. 安装/重新配置 Fail2ban${NC}"
        echo -e "${BLUE}2. 自定义配置 Fail2ban${NC}"
        echo -e "${BLUE}3. 查看 Fail2ban 状态${NC}"
        echo -e "${BLUE}4. 查看当前封禁IP${NC}"
        echo -e "${BLUE}5. 解封指定IP${NC}"
        echo -e "${BLUE}6. 手动封禁IP${NC}"
        echo -e "${BLUE}7. 查看封禁日志${NC}"
        echo -e "${BLUE}0. 退出${NC}"
        
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1)
                install_dependencies
                configure_fail2ban "$(detect_ssh_port)" "3600" "600" "3" ""
                ;;
            2)
                custom_config_menu
                ;;
            3)
                show_status
                ;;
            4)
                show_banned_ips
                ;;
            5)
                read -p "请输入要解封的IP: " ip
                fail2ban-client set sshd unbanip $ip
                echo -e "${GREEN}已解封IP: $ip${NC}"
                ;;
            6)
                read -p "请输入要封禁的IP: " ip
                ban_ip $ip
                ;;
            7)
                case $OS in
                    debian|ubuntu)
                        tail -n 50 /var/log/fail2ban.log
                        ;;
                    centos|rhel|fedora)
                        tail -n 50 /var/log/fail2ban/fail2ban.log
                        ;;
                esac
                ;;
            0)
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
        esac
    done
}

# ... existing code ...
