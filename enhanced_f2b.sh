# ... existing code ...

# 显示封禁IP列表
show_banned_ips() {
    echo -e "${BLUE}当前封禁的IP列表：${NC}"
    
    # 使用 status 命令获取封禁信息
    local status_output=$(fail2ban-client status sshd)
    
    # 提取当前封禁的IP
    local banned_ips=$(echo "$status_output" | grep "Banned IP list:" | sed 's/.*Banned IP list:\s*\(.*\)/\1/')
    
    if [ -z "$banned_ips" ] || [ "$banned_ips" = "[]" ]; then
        echo -e "${YELLOW}当前没有被封禁的IP${NC}"
    else
        # 移除方括号并分割IP
        banned_ips=$(echo "$banned_ips" | tr -d '[]' | tr ',' ' ')
        echo -e "${YELLOW}已封禁的IP列表：${NC}"
        for ip in $banned_ips; do
            echo -e "IP: ${YELLOW}$ip${NC}"
            
            # 获取此IP的失败次数
            local failures=$(fail2ban-client status sshd | grep "Total failed attempts:" | awk '{print $4}')
            echo -e "失败尝试次数: ${YELLOW}${failures:-未知}${NC}"
            
            # 显示分隔线
            echo "----------------------------------------"
        done
        
        # 显示总计
        local total_banned=$(echo "$banned_ips" | wc -w)
        echo -e "\n${BLUE}总计封禁IP数: ${YELLOW}$total_banned${NC}"
    fi
}

# ... existing code ...
