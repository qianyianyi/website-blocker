#!/bin/bash

# 网站屏蔽管理器
# 作者: OpenClaw Assistant

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示横幅
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║          网站访问屏蔽管理器             ║"
    echo "║        Website Access Blocker           ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
        echo -e "${YELLOW}请使用: sudo ./website-blocker.sh${NC}"
        exit 1
    fi
}

# 显示当前屏蔽列表
show_blocked() {
    echo -e "${BLUE}当前已屏蔽的网站:${NC}"
    
    # 检查hosts文件
    if grep -q "^127.0.0.1" /etc/hosts 2>/dev/null; then
        echo -e "${YELLOW}Hosts文件屏蔽:${NC}"
        grep "^127.0.0.1" /etc/hosts | grep -v "localhost" | sed 's/^127.0.0.1 //'
    else
        echo -e "${YELLOW}Hosts文件: 无屏蔽${NC}"
    fi
    
    # 检查iptables规则
    echo -e "\n${YELLOW}防火墙规则:${NC}"
    if command -v iptables &> /dev/null; then
        iptables -L OUTPUT -n | grep DROP | grep -E "dpt:80|dpt:443" || echo "无防火墙屏蔽"
    else
        echo "iptables 未安装"
    fi
}

# 屏蔽网站
block_website() {
    read -p "请输入要屏蔽的网站域名 (例如: example.com): " website
    
    if [[ -z "$website" ]]; then
        echo -e "${RED}错误: 域名不能为空${NC}"
        return 1
    fi
    
    echo -e "${BLUE}正在屏蔽网站: $website${NC}"
    
    # 方法1: 使用hosts文件
    echo -e "${YELLOW}方法1: 添加到hosts文件${NC}"
    if ! grep -q "^127.0.0.1 $website" /etc/hosts; then
        echo "127.0.0.1 $website" >> /etc/hosts
        echo "127.0.0.1 www.$website" >> /etc/hosts
        echo -e "${GREEN}✓ 已添加到hosts文件${NC}"
    else
        echo -e "${YELLOW}⚠ 网站已在hosts文件中${NC}"
    fi
    
    # 方法2: 使用iptables
    echo -e "${YELLOW}方法2: 添加防火墙规则${NC}"
    
    if command -v iptables &> /dev/null; then
        # 获取网站IP
        ip=$(dig +short $website 2>/dev/null | head -1)
        if [[ -n "$ip" ]]; then
            # 屏蔽HTTP
            iptables -C OUTPUT -p tcp -d "$ip" --dport 80 -j DROP 2>/dev/null || iptables -A OUTPUT -p tcp -d "$ip" --dport 80 -j DROP
            # 屏蔽HTTPS
            iptables -C OUTPUT -p tcp -d "$ip" --dport 443 -j DROP 2>/dev/null || iptables -A OUTPUT -p tcp -d "$ip" --dport 443 -j DROP
            echo -e "${GREEN}✓ 已添加防火墙规则 (IP: $ip)${NC}"
        else
            echo -e "${RED}✗ 无法解析域名IP地址${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ iptables 未安装，跳过防火墙配置${NC}"
    fi
    
    echo -e "${GREEN}网站屏蔽完成!${NC}"
}

# 解除屏蔽
unblock_website() {
    read -p "请输入要解除屏蔽的网站域名: " website
    
    if [[ -z "$website" ]]; then
        echo -e "${RED}错误: 域名不能为空${NC}"
        return 1
    fi
    
    echo -e "${BLUE}正在解除屏蔽: $website${NC}"
    
    # 从hosts文件移除
    sed -i "/^127.0.0.1 $website$/d" /etc/hosts 2>/dev/null
    sed -i "/^127.0.0.1 www.$website$/d" /etc/hosts 2>/dev/null
    echo -e "${GREEN}✓ 已从hosts文件移除${NC}"
    
    # 从iptables移除（需要IP）
    if command -v iptables &> /dev/null; then
        ip=$(dig +short $website 2>/dev/null | head -1)
        if [[ -n "$ip" ]]; then
            iptables -D OUTPUT -p tcp -d "$ip" --dport 80 -j DROP 2>/dev/null && echo -e "${GREEN}✓ 已移除HTTP防火墙规则${NC}"
            iptables -D OUTPUT -p tcp -d "$ip" --dport 443 -j DROP 2>/dev/null && echo -e "${GREEN}✓ 已移除HTTPS防火墙规则${NC}"
        fi
    fi
    
    echo -e "${GREEN}网站解除屏蔽完成!${NC}"
}

# 测试屏蔽效果
test_block() {
    read -p "请输入要测试的网站域名: " website
    
    echo -e "${BLUE}测试屏蔽效果:${NC}"
    
    # 测试HTTP
    echo -e "${YELLOW}HTTP测试:${NC}"
    curl -I --connect-timeout 5 "http://$website" 2>&1 | head -1
    
    # 测试HTTPS
    echo -e "${YELLOW}HTTPS测试:${NC}"
    curl -I --connect-timeout 5 "https://$website" 2>&1 | head -1
    
    # 测试DNS解析
    echo -e "${YELLOW}DNS解析测试:${NC}"
    nslookup "$website" 2>&1 | grep "Address:" || echo "DNS解析失败"
}

# 保存防火墙规则
save_rules() {
    echo -e "${BLUE}正在保存防火墙规则...${NC}"
    
    if ! command -v iptables &> /dev/null; then
        echo -e "${YELLOW}⚠ iptables 未安装，无需保存${NC}"
        return
    fi
    
    # 检测系统类型
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        if command -v netfilter-persistent &> /dev/null; then
            netfilter-persistent save
            echo -e "${GREEN}✓ 规则已保存 (Ubuntu/Debian)${NC}"
        else
            echo -e "${YELLOW}正在安装 iptables-persistent...${NC}"
            apt-get update && apt-get install -y iptables-persistent
            netfilter-persistent save
        fi
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        service iptables save
        echo -e "${GREEN}✓ 规则已保存 (CentOS/RHEL)${NC}"
    else
        echo -e "${YELLOW}⚠ 无法自动保存规则，重启后防火墙规则会丢失${NC}"
        echo -e "${YELLOW}请手动保存iptables规则${NC}"
    fi
}

# 主菜单
main_menu() {
    while true; do
        show_banner
        show_blocked
        
        echo -e "\n${BLUE}请选择操作:${NC}"
        echo -e "${GREEN}1. 屏蔽网站${NC}"
        echo -e "${GREEN}2. 解除屏蔽${NC}"
        echo -e "${GREEN}3. 测试屏蔽效果${NC}"
        echo -e "${GREEN}4. 保存防火墙规则${NC}"
        echo -e "${RED}5. 退出${NC}"
        
        read -p "请输入选择 (1-5): " choice
        
        case $choice in
            1)
                block_website
                ;;
            2)
                unblock_website
                ;;
            3)
                test_block
                ;;
            4)
                save_rules
                ;;
            5)
                echo -e "${BLUE}再见!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                ;;
        esac
        
        echo
        read -p "按回车键继续..."
        clear
    done
}

# 脚本入口
check_root
main_menu