# Website Blocker

一个功能强大的网站访问屏蔽管理器，支持多种屏蔽方法和实时测试功能。

## 🚀 功能特色

### 🔧 屏蔽方法
- **Hosts文件屏蔽** - 修改系统hosts文件重定向到本地
- **防火墙屏蔽** - 使用iptables阻止网络连接
- **双重保护** - 同时使用两种方法确保屏蔽效果

### 🎯 管理功能
- **图形化菜单** - 友好的命令行界面
- **实时测试** - 立即验证屏蔽效果
- **规则持久化** - 自动保存防火墙规则
- **解除屏蔽** - 轻松恢复网站访问

### 🔍 监控功能
- **状态查看** - 显示当前屏蔽的网站列表
- **连接测试** - 测试HTTP/HTTPS/DNS连接
- **系统兼容** - 支持多种Linux发行版

## 🛠️ 系统要求

- **操作系统**: Linux (Ubuntu, Debian, CentOS, RHEL等)
- **权限要求**: Root权限
- **依赖工具**: 
  - curl (测试功能)
  - dig/nslookup (DNS解析)
  - iptables (防火墙功能，可选)

## 🚀 使用方法

### 快速开始
```bash
# 下载并运行脚本
bash -c "$(curl -sL https://raw.githubusercontent.com/qianyianyi/website-blocker/main/website-blocker.sh)"

# 或者克隆仓库后运行
git clone https://github.com/qianyianyi/website-blocker.git
cd website-blocker
sudo bash website-blocker.sh
```

### 直接命令使用
```bash
# 快速屏蔽网站
sudo bash -c 'echo "127.0.0.1 example.com" >> /etc/hosts'
sudo bash -c 'echo "127.0.0.1 www.example.com" >> /etc/hosts'

# 快速解除屏蔽
sudo sed -i '/^127.0.0.1 example.com$/d' /etc/hosts
sudo sed -i '/^127.0.0.1 www.example.com$/d' /etc/hosts
```

## 📋 功能菜单

| 编号 | 功能 | 描述 |
|------|------|------|
| 1 | 屏蔽网站 | 添加网站到屏蔽列表 |
| 2 | 解除屏蔽 | 从屏蔽列表移除网站 |
| 3 | 测试屏蔽效果 | 验证屏蔽是否生效 |
| 4 | 保存防火墙规则 | 持久化iptables规则 |
| 5 | 退出 | 退出程序 |

## 🔧 屏蔽原理

### Hosts文件屏蔽
将目标域名指向本地回环地址(127.0.0.1)，使DNS解析失败：
```
127.0.0.1 example.com
127.0.0.1 www.example.com
```

### 防火墙屏蔽
使用iptables直接阻止到目标IP的网络连接：
```bash
iptables -A OUTPUT -p tcp -d example.com --dport 80 -j DROP
iptables -A OUTPUT -p tcp -d example.com --dport 443 -j DROP
```

## ⚠️ 注意事项

1. **权限要求** - 需要root权限修改系统文件
2. **备份重要文件** - 修改前建议备份/etc/hosts
3. **测试效果** - 屏蔽后验证是否生效
4. **合法使用** - 确保屏蔽行为符合法律法规
5. **系统兼容** - 某些系统可能没有iptables

## 🔍 验证屏蔽效果

屏蔽后可以使用以下命令验证：
```bash
# 测试HTTP连接
curl -I http://example.com

# 测试HTTPS连接  
curl -I https://example.com

# 测试DNS解析
nslookup example.com

# 测试ping
ping example.com
```

## 🛠️ 故障排除

### 常见问题
1. **屏蔽不生效** - 检查hosts文件权限和格式
2. **防火墙规则丢失** - 重启后需重新保存规则
3. **DNS缓存** - 清除DNS缓存：`sudo systemd-resolve --flush-caches`

### 系统兼容性
- **Ubuntu/Debian**: 完全支持
- **CentOS/RHEL**: 完全支持  
- **其他Linux**: 基础hosts功能支持

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

---

**注意**: 请负责任地使用此工具，确保您的行为符合当地法律法规。
