#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本号
VERSION="1.0.0"

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
    echo -e "${BLUE}正在配置Fail2ban...${NC}"
    
    # 创建配置目录（如果不存在）
    mkdir -p /etc/fail2ban
    
    # 备份原配置
    if [ -f /etc/fail2ban/jail.local ]; then
        cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 创建新配置
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# 封禁时间（秒）
bantime = 3600
# 检测时间范围（秒）
findtime = 600
# 最大尝试次数
maxretry = 3
# 解封IP
unbantime = 3600
# 忽略本地网络
ignoreip = 127.0.0.1/8 ::1

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

    # 启用并重启服务
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    echo -e "${GREEN}Fail2ban配置完成！${NC}"
    echo -e "${GREEN}当前配置：${NC}"
    echo -e "SSH端口: ${YELLOW}$ssh_port${NC}"
    echo -e "最大尝试次数: ${YELLOW}3${NC}"
    echo -e "封禁时间: ${YELLOW}1小时${NC}"
    echo -e "检测时间范围: ${YELLOW}10分钟${NC}"
}

# 显示状态
show_status() {
    echo -e "${BLUE}Fail2ban状态：${NC}"
    systemctl status fail2ban
    echo -e "\n${BLUE}已封禁的IP：${NC}"
    fail2ban-client status sshd
}

# 主菜单
main_menu() {
    while true; do
        echo -e "\n${GREEN}=== Fail2ban 管理脚本 v${VERSION} ===${NC}"
        echo -e "${BLUE}1. 安装/重新配置 Fail2ban${NC}"
        echo -e "${BLUE}2. 查看Fail2ban状态${NC}"
        echo -e "${BLUE}3. 解封指定IP${NC}"
        echo -e "${BLUE}4. 查看封禁日志${NC}"
        echo -e "${BLUE}0. 退出${NC}"
        
        read -p "请选择操作 [0-4]: " choice
        
        case $choice in
            1)
                local detected_port=$(detect_ssh_port)
                echo -e "${YELLOW}检测到当前SSH端口为: $detected_port${NC}"
                read -p "是否使用此端口配置Fail2ban？[Y/n]: " confirm
                if [[ $confirm =~ ^[Nn]$ ]]; then
                    read -p "请输入新的SSH端口: " new_port
                    ssh_port=$new_port
                else
                    ssh_port=$detected_port
                fi
                install_dependencies
                configure_fail2ban $ssh_port
                ;;
            2)
                show_status
                ;;
            3)
                read -p "请输入要解封的IP: " ip
                fail2ban-client set sshd unbanip $ip
                echo -e "${GREEN}已解封IP: $ip${NC}"
                ;;
            4)
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
