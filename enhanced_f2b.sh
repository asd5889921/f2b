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
    
    # 备份现有的fail2ban配置（如果存在）
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
check_base_dependencies() {
    log "${BLUE}检查基础依赖...${NC}"
    
    # 检查包管理器
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
        PKG_REMOVE="apt remove -y"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update || true"  # 防止返回值1导致脚本退出
        PKG_INSTALL="dnf install -y"
        PKG_REMOVE="dnf remove -y"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum check-update || true"  # 防止返回值1导致脚本退出
        PKG_INSTALL="yum install -y"
        PKG_REMOVE="yum remove -y"
    else
        handle_error "未找到支持的包管理器"
    fi
    
    # 基础依赖列表
    local base_deps=("curl" "wget" "systemd" "grep" "sed" "awk" "tar" "gzip" "cron" "net-tools")
    local missing_deps=()
    
    # 检查每个依赖
    for dep in "${base_deps[@]}"; do
        if ! command -v $dep >/dev/null 2>&1; then
            missing_deps+=($dep)
        fi
    done
    
    # 如果有缺失的依赖，则安装
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "${YELLOW}正在安装缺失的基础依赖: ${missing_deps[*]}${NC}"
        $PKG_UPDATE
        $PKG_INSTALL "${missing_deps[@]}" || handle_error "安装基础依赖失败"
    fi
    log "${GREEN}基础依赖检查完成${NC}"
}

# 检查防火墙状态
check_firewall() {
    log "${BLUE}检查防火墙状态...${NC}"
    
    case $OS in
        debian|ubuntu)
            if command -v ufw >/dev/null 2>&1; then
                if ufw status | grep -q "active"; then
                    log "${YELLOW}检测到UFW防火墙正在运行${NC}"
                    log "${BLUE}配置UFW规则...${NC}"
                    ufw allow ssh
                    ufw reload
                fi
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd >/dev/null 2>&1; then
                if systemctl is-active firewalld >/dev/null 2>&1; then
                    log "${YELLOW}检测到FirewallD防火墙正在运行${NC}"
                    log "${BLUE}配置FirewallD规则...${NC}"
                    firewall-cmd --permanent --add-service=ssh
                    firewall-cmd --reload
                fi
            fi
            ;;
    esac
}

# 检查SELinux状态
check_selinux() {
    if command -v getenforce >/dev/null 2>&1; then
        selinux_status=$(getenforce)
        if [ "$selinux_status" != "Disabled" ]; then
            log "${YELLOW}检测到SELinux已启用（$selinux_status）${NC}"
            log "${BLUE}配置SELinux策略...${NC}"
            $PKG_INSTALL policycoreutils-python-utils || true
            semanage port -a -t ssh_port_t -p tcp 22 || true
        fi
    fi
}

# 检查并安装Fail2ban依赖
install_fail2ban() {
    log "${BLUE}安装Fail2ban及其依赖...${NC}"
    
    local fail2ban_deps=()
    
    case $OS in
        debian|ubuntu)
            if [ "$VERSION_ID" = "12" ]; then
                fail2ban_deps=("fail2ban" "iptables" "ipset" "whois" "python3" "python3-systemd" "nftables")
            else
                fail2ban_deps=("fail2ban" "iptables" "ipset" "whois")
            fi
            ;;
        centos|rhel|fedora)
            # 安装EPEL仓库
            if [ "$PKG_MANAGER" = "dnf" ]; then
                $PKG_INSTALL epel-release
            else
                $PKG_INSTALL epel-release
            fi
            fail2ban_deps=("fail2ban" "fail2ban-systemd" "iptables" "ipset" "whois")
            ;;
    esac
    
    # 安装依赖
    $PKG_UPDATE
    for dep in "${fail2ban_deps[@]}"; do
        log "${BLUE}安装 $dep...${NC}"
        $PKG_INSTALL "$dep" || handle_error "安装 $dep 失败"
    done
}

# 配置Fail2ban
configure_fail2ban() {
    log "${BLUE}配置Fail2ban...${NC}"
    
    # 创建配置目录
    mkdir -p /etc/fail2ban
    
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
banaction = %(banaction_allports)s
banaction_allports = iptables-allports

[sshd]
enabled = true
port = ssh
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
    
    # 创建自定义过滤器目录
    mkdir -p /etc/fail2ban/filter.d
    
    # 配置sshd过滤器（增强版）
    cat > /etc/fail2ban/filter.d/sshd.local << EOF
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
            ^%(__prefix_line)sUser .+ from <HOST> not allowed because not listed in AllowUsers\s*$
            ^%(__prefix_line)sUser .+ from <HOST> not allowed because listed in DenyUsers\s*$
            ^%(__prefix_line)sUser .+ from <HOST> not allowed because not in any group\s*$
            ^%(__prefix_line)srefused connect from \S+ \(<HOST>\)\s*$
            ^%(__prefix_line)sReceived disconnect from <HOST>: 3: \S+: Auth fail$
            ^%(__prefix_line)sUser .+ from <HOST> not allowed because a group is listed in DenyGroups\s*$
            ^%(__prefix_line)sUser .+ from <HOST> not allowed because none of user's groups are listed in AllowGroups\s*$
            ^%(__prefix_line)spam_unix\(sshd:auth\):\s+authentication failure;\s*logname=\S*\s*uid=\d*\s*euid=\d*\s*tty=\S*\s*ruser=\S*\s*rhost=<HOST>\s.*$

ignoreregex = 

[Init]
maxlines = 10
EOF
}

# 配置系统自启动
configure_autostart() {
    log "${BLUE}配置系统自启动...${NC}"
    
    # 创建systemd服务单元
    cat > /lib/systemd/system/fail2ban.service << EOF
[Unit]
Description=Fail2Ban Service
Documentation=man:fail2ban(1)
After=network.target iptables.service nftables.service

[Service]
Type=simple
ExecStart=/usr/bin/fail2ban-server -f -x
ExecStop=/usr/bin/fail2ban-client stop
ExecReload=/usr/bin/fail2ban-client reload
PIDFile=/var/run/fail2ban/fail2ban.pid
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启用并启动服务
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    # 检查服务状态
    if ! systemctl is-active fail2ban >/dev/null 2>&1; then
        handle_error "fail2ban服务未能正常启动，请检查日志"
    fi
    log "${GREEN}fail2ban服务已成功启动并设置为开机自启${NC}"
}

# 配置日志轮转
configure_logrotate() {
    log "${BLUE}配置日志轮转...${NC}"
    
    cat > /etc/logrotate.d/fail2ban << EOF
/var/log/fail2ban.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    postrotate
        fail2ban-client set logtarget /var/log/fail2ban.log >/dev/null
    endscript
}
EOF
}

# 创建快捷命令
create_shortcuts() {
    log "${BLUE}创建快捷命令...${NC}"
    
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

# 显示安装完成信息
show_completion() {
    local ssh_port=$(grep -oP '^Port\s+\K\d+' /etc/ssh/sshd_config 2>/dev/null || echo 22)
    local public_ip=$(curl -s ifconfig.me || wget -qO- ifconfig.me)
    
    log "\n${GREEN}=== Fail2ban 安装完成 ===${NC}"
    log "${BLUE}基本信息：${NC}"
    log "- SSH端口: ${YELLOW}$ssh_port${NC}"
    log "- 公网IP: ${YELLOW}$public_ip${NC}"
    log "- 配置文件: ${YELLOW}/etc/fail2ban/jail.local${NC}"
    log "- 日志文件: ${YELLOW}/var/log/fail2ban.log${NC}"
    
    log "\n${BLUE}快捷命令使用方法：${NC}"
    log "- 查看状态: ${YELLOW}f2b status${NC}"
    log "- 查看封禁: ${YELLOW}f2b banned${NC}"
    log "- 封禁IP:  ${YELLOW}f2b ban <IP>${NC}"
    log "- 解封IP:  ${YELLOW}f2b unban <IP>${NC}"
    log "- 查看日志: ${YELLOW}f2b log${NC}"
    
    log "\n${BLUE}备份信息：${NC}"
    log "- 备份目录: ${YELLOW}$BACKUP_DIR${NC}"
    log "- 安装日志: ${YELLOW}$LOG_FILE${NC}"
    
    log "\n${GREEN}现在您可以使用上述命令来管理Fail2ban了！${NC}"
}

# 主函数
main() {
    clear
    echo -e "${GREEN}=== Fail2ban 增强版安装脚本 v${VERSION} ===${NC}"
    echo -e "${BLUE}正在准备安装...${NC}\n"
    
    # 初始化
    check_root
    init_log
    create_backup
    get_system_info
    
    # 系统准备
    check_base_dependencies
    check_firewall
    check_selinux
    
    # 安装配置
    install_fail2ban
    configure_fail2ban
    configure_autostart
    configure_logrotate
    create_shortcuts
    
    # 完成
    show_completion
}

# 执行主函数
main
