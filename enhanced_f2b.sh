# 创建脚本
cat > enhanced_f2b_custom.sh << 'EOF'
#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本号
VERSION="1.1.1"

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本需要root权限运行${NC}"
        echo -e "${YELLOW}请使用 sudo -i 获取root权限后再运行${NC}"
        exit 1
    fi
}

# 获取系统信息
get_system_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
    else
        echo -e "${RED}无法确定操作系统类型${NC}"
        exit 1
    fi
}

# 检测当前SSH端口
detect_ssh_port() {
    if command -v netstat >/dev/null 2>&1; then
        current_ssh_port=$(netstat -tlpn | grep "sshd" | awk '{print $4}' | cut -d: -f2)
    elif command -v ss >/dev/null 2>&1; then
        current_ssh_port=$(ss -tlpn | grep "sshd" | awk '{print $4}' | cut -d: -f2)
    else
        current_ssh_port=22
    fi
    echo $current_ssh_port
}

# 安装依赖
install_dependencies() {
    echo -e "${BLUE}正在安装必要的依赖...${NC}"
    case $OS in
        debian|ubuntu)
            apt update
            apt install -y fail2ban curl wget
            ;;
        centos|rhel|fedora)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y epel-release
                dnf install -y fail2ban curl wget
            else
                yum install -y epel-release
                yum install -y fail2ban curl wget
            fi
            ;;
        *)
            echo -e "${RED}不支持的操作系统${NC}"
            exit 1
            ;;
    esac
}

# 配置Fail2ban
configure_fail2ban() {
    local ssh_port=$1
    local bantime=$2
    local findtime=$3
    local maxretry=$4
    local whitelist=$5
    
    echo -e "${BLUE}正在配置Fail2ban...${NC}"
    
    # 创建配置目录（如果不存在）
    mkdir -p /etc/fail2ban
    
    # 备份原配置
    if [ -f /etc/fail2ban/jail.local ]; then
        cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 创建新配置
    cat > /etc/fail2ban/jail.local << EEOF
[DEFAULT]
# 封禁时间（秒）
bantime = $bantime
# 检测时间范围（秒）
findtime = $findtime
# 最大尝试次数
maxretry = $maxretry
# 解封IP
unbantime = $bantime
# 忽略本地网络
ignoreip = 127.0.0.1/8 ::1 $whitelist

[sshd]
enabled = true
port = $ssh_port
filter = sshd
logpath = %(sshd_log)s
maxretry = $maxretry
EEOF

    # 根据不同系统配置日志路径
    case $OS in
        debian|ubuntu)
            sed -i 's|%(sshd_log)s|/var/log/auth.log|' /etc/fail2ban/jail.local
            ;;
        centos|rhel|fedora)
            sed -i 's|%(sshd_log)s|/var/log/secure|' /etc/fail2ban/jail.local
            ;;
    esac

    # 启用并重启服务
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    echo -e "${GREEN}Fail2ban配置完成！${NC}"
    echo -e "${GREEN}当前配置：${NC}"
    echo -e "SSH端口: ${YELLOW}$ssh_port${NC}"
    echo -e "最大尝试次数: ${YELLOW}$maxretry${NC}"
    echo -e "封禁时间: ${YELLOW}$(($bantime/3600))小时${NC}"
    echo -e "检测时间范围: ${YELLOW}$(($findtime/60))分钟${NC}"
    echo -e "白名单IP: ${YELLOW}$whitelist${NC}"
}

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

# 手动封禁IP
ban_ip() {
    local ip=$1
    fail2ban-client set sshd banip $ip
    echo -e "${GREEN}已封禁IP: $ip${NC}"
}

# 显示状态
show_status() {
    echo -e "${BLUE}Fail2ban状态：${NC}"
    systemctl status fail2ban
    echo -e "\n${BLUE}已封禁的IP：${NC}"
    fail2ban-client status sshd
}

# 自定义配置菜单
custom_config_menu() {
    local detected_port=$(detect_ssh_port)
    echo -e "${YELLOW}检测到当前SSH端口为: $detected_port${NC}"
    read -p "是否使用此端口配置Fail2ban？[Y/n]: " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        read -p "请输入新的SSH端口: " new_port
        ssh_port=$new_port
    else
        ssh_port=$detected_port
    fi

    read -p "请输入封禁时间（小时，默认1小时）: " ban_hours
    ban_hours=${ban_hours:-1}
    bantime=$((ban_hours * 3600))

    read -p "请输入检测时间范围（分钟，默认10分钟）: " find_minutes
    find_minutes=${find_minutes:-10}
    findtime=$((find_minutes * 60))

    read -p "请输入最大尝试次数（默认3次）: " max_retry
    maxretry=${max_retry:-3}

    read -p "请输入白名单IP（多个IP用空格分隔，直接回车跳过）: " whitelist
    whitelist=${whitelist:-""}

    install_dependencies
    configure_fail2ban "$ssh_port" "$bantime" "$findtime" "$maxretry" "$whitelist"
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

# 程序入口
check_root
get_system_info
main_menu
EOF

# 添加执行权限
chmod +x enhanced_f2b_custom.sh

# 运行脚本
./enhanced_f2b_custom.sh
