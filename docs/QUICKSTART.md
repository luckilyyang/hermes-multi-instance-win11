# ⚡ Windows 11 快速开始指南

## 5 分钟快速部署

### 前置条件
- Windows 11
- Docker Desktop 已安装
- 16GB 内存以上

### 第一步：配置 hosts 文件

1. 以**管理员身份**打开记事本
2. 打开文件：`C:\Windows\System32\drivers\etc\hosts`
3. 在文件末尾添加：
```
127.0.0.1 super.xx.local
127.0.0.1 ls.xx.local
127.0.0.1 zs.xx.local
127.0.0.1 admin.xx.local
```
4. 保存文件
5. 打开 PowerShell 运行：
```powershell
ipconfig /flushdns
```

### 第二步：启动系统

```powershell
# 1. 进入项目目录
cd D:\your\project\path\hermes-multi-instance-win11

# 2. 复制环境文件
Copy-Item ".env.example" ".env"

# 3. 启动所有服务
docker-compose up -d

# 4. 等待 30 秒
Start-Sleep -Seconds 30

# 5. 检查状态
docker-compose ps
```

### 第三步：访问服务

打开浏览器访问：

| 服务 | 地址 | 用户名 | 密码 |
|------|------|--------|------|
| 🌐 中央管理面板 | http://admin.xx.local:5000 | superadmin | admin123 |
| 👑 超级管理员 | http://super.xx.local | admin | admin123 |
| 👤 LS 管理员 | http://ls.xx.local | admin | admin123 |
| 👤 ZS 管理员 | http://zs.xx.local | admin | admin123 |

> ⚠️ 首次登录后立即修改密码！

---

## 🧪 功能测试

### 1️⃣ 测试中央管理面板

```
1. 打开 http://admin.xx.local:5000
2. 使用 superadmin/admin123 登录
3. 查看"概览"标签页
   ✅ 应显示 3 个实例（super, ls, zs）都在线
   ✅ 用户数应为 3
4. 切换到"用户管理"标签页
   ✅ 应显示 admin 用户在 3 个实例中
```

### 2️⃣ 测试跨实例用户创建

```
1. 在中央管理面板的"用户管理"标签页
2. 点击"➕ 创建全局用户"
3. 输入：
   - 用户名: test_user
   - 密码: TestPassword123
   - 邮箱: test@example.com
4. 创建后验证：
   ✅ 用户出现在列表中
   ✅ 该用户在 3 个实例中都可见
```

### 3️⃣ 测试在不同实例创建会话

```
# 在 super 实例
1. 打开 http://super.xx.local
2. 使用 test_user/TestPassword123 登录
3. 创建一个新的聊天会话
4. 发送一条消息测试

# 在 ls 实例
1. 打开 http://ls.xx.local
2. 使用 test_user/TestPassword123 登录
3. 验证会话列表
   ✅ 不应该看到在 super 实例创建的会话（数据隔离）
4. 创建一个新的会话

# 回到中央管理面板
1. 打开 http://admin.xx.local:5000
2. 进入"Token 统计"标签页
3. 查询 test_user 的统计
   ✅ 应显示在 super 和 ls 实例各有一次调用
```

### 4️⃣ 测试权限隔离

```
# 在 ls 实例
1. 以 test_user 身份登录 http://ls.xx.local
2. 进入管理界面
   ✅ 应该有权限管理用户（admin 权限）
3. 创建新用户
   ✅ 只有 ls 实例中能看到这个用户

# 回到 super 实例
1. 以 admin 身份登录 http://super.xx.local
2. 查看用户列表
   ✅ 不应该看到在 ls 实例中新建的用户
```

### 5️⃣ 测试操作日志

```
1. 在中央管理面板打开"操作日志"标签页
2. 查看最近的操作
   ✅ 应显示你在 3 个实例中的所有操作
   ✅ 包括用户创建、会话创建等
3. 按实例过滤
   ✅ 可以单独查看某个实例的操作
```

---

## 🔧 常用命令

### 启动/停止

```powershell
# 启动所有服务
.\scripts\start.ps1

# 停止所有服务
.\scripts\stop.ps1

# 查看特定服务日志
.\scripts\logs.ps1 admin-dashboard
.\scripts\logs.ps1 studio-super
.\scripts\logs.ps1 studio-ls
.\scripts\logs.ps1 studio-zs
```

### Docker 命令

```powershell
# 查看所有容器
docker-compose ps

# 查看实时日志
docker-compose logs -f

# 进入容器
docker exec -it admin-dashboard bash

# 重启单个容器
docker-compose restart studio-super

# 停止并删除数据
docker-compose down -v
```

---

## 🆘 常见问题快速解决

### Q: 无法访问 admin.xx.local

```powershell
# 1. 检查 hosts 文件
Get-Content C:\Windows\System32\drivers\etc\hosts | findstr "admin.xx.local"

# 2. 刷新 DNS
ipconfig /flushdns

# 3. 测试 DNS
[System.Net.Dns]::GetHostAddresses("admin.xx.local")
```

### Q: 容器无法启动

```powershell
# 查看详细错误
docker-compose logs admin-dashboard

# 重新构建
docker-compose build --no-cache

# 重新启动
docker-compose up -d
```

### Q: 数据库连接失败

```powershell
# 测试 PostgreSQL
docker exec postgres-super psql -U hermes -d hermes_studio -c "SELECT 1"

# 测试 MongoDB
docker exec mongo-central mongosh admin -u admin -p admin123 --eval "db.adminCommand('ping')"

# 测试 Redis
docker exec redis-central redis-cli -a redis123 ping
```

### Q: 某个实例无法创建会话

```powershell
# 检查实例日志
docker-compose logs studio-super

# 检查数据库
docker exec postgres-super psql -U hermes -d hermes_studio -c "SELECT * FROM sessions LIMIT 5"

# 重启实例
docker-compose restart studio-super
```

---

## 📊 性能监控

```powershell
# 实时监控 Docker 资源使用
docker stats

# 查看容器详细信息
docker inspect hermes-admin-dashboard

# 查看日志大小
docker exec admin-dashboard du -sh /app/logs
```

---

## 🚀 下一步

### 本地测试完成后

1. ✅ 验证所有功能正常
2. ✅ 测试数据备份和恢复
3. ✅ 记录当前配置
4. ✅ 准备迁移到服务器

### 迁移到服务器

查看文件：[SERVER_DEPLOYMENT.md](SERVER_DEPLOYMENT.md)

---

## 📞 获取帮助

如遇问题，请：

1. 查看 [FAQ.md](FAQ.md) 获取常见问题答案
2. 查看完整日志：`docker-compose logs`
3. 检查 GitHub Issues：https://github.com/luckilyyang/hermes-multi-instance-win11/issues
4. 查看项目文档：[README.md](../README.md)
