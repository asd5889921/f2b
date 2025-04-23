#!/bin/bash

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 版本号
VERSION="1.2.1"

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
    echo -e "${RED}9.${NC} 卸载 Fail2ban"
    echo -e "${BLUE}0.${NC} 退出"
    echo
    echo -e "${YELLOW}请输入选项 [0-9]:${NC} "
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
        
        # Debian 12 需要特殊处理
        if [ "$OS" = "debian" ] && [ "$VERSION_ID" = "12" ]; then
            $PKG_UPDATE
            # 安装必需的依赖
            $PKG_INSTALL fail2ban python3 python3-systemd iptables rsyslog || handle_error "安装失败"
            
            # 确保rsyslog服务启动并开机自启
            systemctl enable rsyslog
            systemctl start rsyslog
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

# 配置Fail2ban
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

# 使用rsyslog作为后端
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

# 卸载Fail2ban
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
                apt remove --purge -y fail2ban
                ;;
            centos|rhel|fedora)
                yum remove -y fail2ban
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

# 查看状态
show_status() {
    clear
    echo -e "${GREEN}=== Fail2ban 状态 ===${NC}"
    
    # 检查服务运行状态
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${GREEN}● Fail2ban 服务状态: 正在运行${NC}"
    else
        echo -e "${RED}○ Fail2ban 服务状态: 未运行${NC}"
    fi
    
    # 检查是否开机自启
    if systemctl is-enabled fail2ban >/dev/null 2>&1; then
        echo -e "${GREEN}● 开机自启: 已启用${NC}"
    else
        echo -e "${YELLOW}○ 开机自启: 未启用${NC}"
    fi
    
    # 显示运行时间
    echo -e "\n${BLUE}运行时间:${NC}"
    systemctl status fail2ban | grep "Active:" | sed 's/Active:/运行时长:/' || echo -e "${RED}无法获取运行时间${NC}"
    
    echo -e "\n${BLUE}监狱状态:${NC}"
    fail2ban-client status
    
    echo -e "\n${BLUE}详细信息:${NC}"
    fail2ban-client status sshd | grep "Currently banned:" || echo -e "${YELLOW}当前没有被封禁的IP${NC}"
    
    echo -e "\n${YELLOW}按回车键返回主菜单${NC}"
    read
}

# 查看封禁IP
show_banned() {
    clear
    echo -e "${GREEN}=== 当前封禁IP列表 ===${NC}"
    
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        echo -e "${GREEN}● 服务状态: 正在运行${NC}\n"
        
        # 获取封禁信息
        banned_info=$(fail2ban-client status sshd)
        if echo "$banned_info" | grep -q "Currently banned:.*[1-9]"; then
            echo -e "${BLUE}封禁详情:${NC}"
            echo "$banned_info"
        else
            echo -e "${YELLOW}目前没有被封禁的IP${NC}"
        fi
    else
        echo -e "${RED}○ 服务状态: 未运行${NC}"
        echo -e "${RED}请先启动Fail2ban服务${NC}"
    fi
    
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
            9) uninstall_fail2ban ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选项${NC}" ; sleep 1 ;;
        esac
    done
}

# 执行主函数
main 
