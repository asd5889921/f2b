#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本号
VERSION="1.2.0"

# 全局变量
BACKUP_DIR="/root/fail2ban_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/fail2ban_install.log"

# 日志函数
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# 错误处理函数
handle_error() {
    log "${RED}错误：$1${NC}"
    log "${YELLOW}详细错误信息已保存到：$LOG_FILE${NC}"
    exit 1
}

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        handle_error "此脚本需要root权限运行\n请使用 sudo -i 获取root权限后再运行"
    fi
}

# 显示菜单
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
    echo -e "${BLUE}0.${NC} 退出"
    echo
    echo -e "${YELLOW}请输入选项 [0-8]:${NC} "
}

# 初始化日志
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log "${BLUE}=== Fail2ban 安装日志 - $(date) ===${NC}"
}

# 创建备份目录
create_backup() {
    mkdir -p "$BACKUP_DIR"
    log "${BLUE}创建备份目录：$BACKUP_DIR${NC}"
    
    if [ -d "/etc/fail2ban" ]; then
        cp -r /etc/fail2ban "$BACKUP_DIR/"
        log "${GREEN}已备份现有fail2ban配置${NC}"
    fi
}

# 获取系统信息
get_system_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID
        log "${BLUE}检测到系统：$OS $VERSION_ID${NC}"
    else
        handle_error "无法确定操作系统类型"
    fi
}

# 检查并安装基础依赖
install_dependencies() {
    log "${BLUE}检查基础依赖...${NC}"
    
    # 检查包管理器
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update || true"
        PKG_INSTALL="dnf install -y"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update || true"
        PKG_INSTALL="yum install -y"
    else
        handle_error "未找到支持的包管理器"
    fi
    
    # 最小化必要依赖
    case $OS in
        debian|ubuntu)
            $PKG_UPDATE
            $PKG_INSTALL fail2ban iptables || handle_error "安装失败"
            ;;
        centos|rhel|fedora)
            $PKG_INSTALL epel-release
            $PKG_INSTALL fail2ban iptables || handle_error "安装失败"
            ;;
    esac
    
    log "${GREEN}基础依赖安装完成${NC}"
}

# 配置Fail2ban
configure_fail2ban() {
    log "${BLUE}配置Fail2ban...${NC}"
    
    # 创建配置目录
    mkdir -p /etc/fail2ban
    
    # 获取SSH端口
    local ssh_port=$(grep -oP '^Port\s+\K\d+' /etc/ssh/sshd_config 2>/dev/null || echo 22)
    
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

# 创建快捷命令
create_shortcuts() {
    cat > /usr/local/bin/f2b << EOF
#!/bin/bash
case "\$1" in
    status)
        fail2ban-client status
        ;;
    banned)
        fail2ban-client status sshd
        ;;
    unban)
        if [ -z "\$2" ]; then
            echo "使用方法: f2b unban <IP>"
        else
            fail2ban-client set sshd unbanip \$2
        fi
        ;;
    ban)
        if [ -z "\$2" ]; then
            echo "使用方法: f2b ban <IP>"
        else
            fail2ban-client set sshd banip \$2
        fi
        ;;
    log)
        tail -f /var/log/fail2ban.log
        ;;
    *)
        echo "使用方法: f2b {status|banned|unban|ban|log}"
        ;;
esac
EOF

    chmod +x /usr/local/bin/f2b
    log "${GREEN}已创建快捷命令 'f2b'${NC}"
}

# 安装Fail2ban
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
    
    # 启动服务
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    if ! systemctl is-active fail2ban >/dev/null 2>&1; then
        handle_error "fail2ban服务未能正常启动，请检查日志"
    fi
    
    echo -e "\n${GREEN}Fail2ban 安装完成！${NC}"
    echo -e "${BLUE}当前状态：${NC}"
    fail2ban-client status
    
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 查看状态
show_status() {
    clear
    echo -e "${GREEN}=== Fail2ban 状态 ===${NC}"
    fail2ban-client status
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 查看封禁IP
show_banned() {
    clear
    echo -e "${GREEN}=== 当前封禁IP列表 ===${NC}"
    fail2ban-client status sshd
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 解封IP
unban_ip() {
    clear
    echo -e "${GREEN}=== 解封IP ===${NC}"
    echo -e "${BLUE}当前封禁的IP：${NC}"
    fail2ban-client status sshd
    echo
    echo -e "${YELLOW}请输入要解封的IP（输入 'q' 返回）：${NC}"
    read -r ip
    
    if [ "$ip" != "q" ]; then
        fail2ban-client set sshd unbanip "$ip"
        echo -e "${GREEN}操作完成${NC}"
        sleep 2
    fi
}

# 手动封禁IP
ban_ip() {
    clear
    echo -e "${GREEN}=== 手动封禁IP ===${NC}"
    echo -e "${YELLOW}请输入要封禁的IP（输入 'q' 返回）：${NC}"
    read -r ip
    
    if [ "$ip" != "q" ]; then
        fail2ban-client set sshd banip "$ip"
        echo -e "${GREEN}操作完成${NC}"
        sleep 2
    fi
}

# 查看日志
show_log() {
    clear
    echo -e "${GREEN}=== 封禁日志 ===${NC}"
    tail -n 50 /var/log/fail2ban.log
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 修改配置
edit_config() {
    clear
    echo -e "${GREEN}=== 修改配置 ===${NC}"
    echo -e "${BLUE}1.${NC} 修改封禁时间"
    echo -e "${BLUE}2.${NC} 修改最大尝试次数"
    echo -e "${BLUE}3.${NC} 修改检测时间范围"
    echo -e "${BLUE}4.${NC} 添加IP白名单"
    echo -e "${BLUE}0.${NC} 返回主菜单"
    echo
    echo -e "${YELLOW}请选择 [0-4]:${NC} "
    read -r choice
    
    case $choice in
        1)
            echo -e "${YELLOW}请输入新的封禁时间（秒）：${NC}"
            read -r bantime
            sed -i "s/bantime = .*/bantime = $bantime/" /etc/fail2ban/jail.local
            ;;
        2)
            echo -e "${YELLOW}请输入新的最大尝试次数：${NC}"
            read -r maxretry
            sed -i "s/maxretry = .*/maxretry = $maxretry/" /etc/fail2ban/jail.local
            ;;
        3)
            echo -e "${YELLOW}请输入新的检测时间范围（秒）：${NC}"
            read -r findtime
            sed -i "s/findtime = .*/findtime = $findtime/" /etc/fail2ban/jail.local
            ;;
        4)
            echo -e "${YELLOW}请输入要添加的IP（空格分隔多个IP）：${NC}"
            read -r ips
            current_ignoreip=$(grep "^ignoreip =" /etc/fail2ban/jail.local)
            sed -i "s|$current_ignoreip|ignoreip = 127.0.0.1/8 ::1 $ips|" /etc/fail2ban/jail.local
            ;;
    esac
    
    if [ "$choice" != "0" ]; then
        systemctl restart fail2ban
        echo -e "${GREEN}配置已更新并重启服务${NC}"
        sleep 2
    fi
}

# 重启服务
restart_service() {
    clear
    echo -e "${GREEN}正在重启 Fail2ban 服务...${NC}"
    systemctl restart fail2ban
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${GREEN}服务重启成功${NC}"
    else
        echo -e "${RED}服务重启失败，请检查日志${NC}"
    fi
    sleep 2
}

# 主循环
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
            0) exit 0 ;;
            *) echo -e "${RED}无效选项${NC}" ; sleep 1 ;;
        esac
    done
}

# 执行主函数
main
