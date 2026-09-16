# Hermes Studio 多实例中央管理 - Windows 11 本地部署指南

这是一个完整的 Windows 11 本地部署方案，包括 Docker 方案和本地运行方案。

## 🎯 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│          🌐 中央管理面板 (admin.xx.local:5000)              │
│          ✅ 查看所有用户和实例                               │
│          ✅ 监控 Token 消耗                                  │
│          ✅ 查看操作日志                                    │
│          ✅ 管理配额和权限                                  │
└────────┬────────────────────────┬──────────────┬───────────┘
         │                        │              │
    ┌────▼──────┐          ┌──────▼────┐   ┌────▼──────┐
    │Super实例   │          │LS实例     │   │ZS实例     │
    │6060       │          │6061      │   │6062      │
    │super.xx.local        │ls.xx.local   │zs.xx.local │
    └────┬──────┘          └──────┬────┘   └────┬──────┘
         │                        │              │
  ┌──────▼────────┐      ┌────────▼───────┐ ┌──▼────────────┐
  │ PostgreSQL1   │      │ PostgreSQL2    │ │PostgreSQL3    │
  │ Port: 5432    │      │ Port: 5433     │ │Port: 5434     │
  └──────────────┘      └────────────────┘ └───────────────┘
         │                        │              │
         └────────────────────┬───┴──────────────┘
                              │
                    ┌─────────▼─────────┐
                    │ MongoDB (27017)   │
                    │ Redis (6379)      │
                    └───────────────────┘
```

## 📋 前置要求

### 硬件要求
- RAM: 16GB 以上
- 硬盘: 50GB 以上可用空间
- CPU: 4核以上

### 软件要求（选一种方案）

**方案 A (推荐): Docker 方案**
- Docker Desktop for Windows (自带 WSL2 和 Compose)
- 无需其他依赖

**方案 B: 本地运行方案**
- Node.js 23+
- PostgreSQL 16
- MongoDB 7
- Redis 7
- Git

---

## 🚀 方案 A: Docker 部署（推荐）

### 第一步：安装 Docker Desktop

1. **下载 Docker Desktop for Windows**
   - 访问: https://www.docker.com/products/docker-desktop
   - 下载 "Docker Desktop for Windows"
   - 运行安装程序

2. **安装过程**
   - 选择 "Install required Windows components for WSL 2"
   - 完成安装后重启计算机

3. **验证安装**
   ```powershell
   docker --version
   docker-compose --version
   ```

### 第二步：配置 hosts 文件

1. **编辑 hosts 文件**
   - 打开记事本 (以管理员身份)
   - 打开文件: `C:\Windows\System32\drivers\etc\hosts`
   - 在文件末尾添加:
   ```
   127.0.0.1 super.xx.local
   127.0.0.1 ls.xx.local
   127.0.0.1 zs.xx.local
   127.0.0.1 admin.xx.local
   ```
   - 保存文件

2. **刷新 DNS 缓存**
   ```powershell
   ipconfig /flushdns
   ```

3. **验证配置**
   ```powershell
   ping super.xx.local
   ping admin.xx.local
   ```
   应该返回 127.0.0.1

### 第三步：克隆和启动

1. **克隆项目**
   ```powershell
   # 打开 PowerShell (可选：以管理员身份)
   cd D:\Projects  # 选择一个合适的目录
   git clone https://github.com/luckilyyang/hermes-multi-instance-win11.git
   cd hermes-multi-instance-win11
   ```

2. **创建环境文件**
   ```powershell
   Copy-Item ".env.example" ".env"
   ```

3. **启动所有服务**
   ```powershell
   docker-compose up -d
   ```
   
   首次启动会下载镜像，可能需要 5-10 分钟

4. **检查服务状态**
   ```powershell
   docker-compose ps
   ```
   
   所有容器状态应为 "Up"

5. **等待初始化完成**
   ```powershell
   Start-Sleep -Seconds 30
   ```

### 第四步：访问服务

打开浏览器访问:

| 服务 | 地址 | 用户名 | 密码 |
|------|------|--------|------|
| 🎛️ 中央管理面板 | http://admin.xx.local:5000 | superadmin | admin123 |
| 👑 超级管理员 | http://super.xx.local | admin | admin123 |
| 👤 LS 管理员 | http://ls.xx.local | admin | admin123 |
| 👤 ZS 管理员 | http://zs.xx.local | admin | admin123 |

> ⚠️ 首次登录后请立即修改密码！

### Docker 常用命令

```powershell
# 查看所有容器状态
docker-compose ps

# 查看特定容器日志
docker-compose logs -f admin-dashboard
docker-compose logs -f studio-super
docker-compose logs -f studio-ls

# 重启服务
docker-compose restart studio-super

# 停止所有服务
docker-compose down

# 删除所有数据（谨慎！）
docker-compose down -v

# 查看 PostgreSQL 日志
docker exec postgres-super psql -U hermes -d hermes_studio -c "SELECT 1"

# 进入容器执行命令
docker exec -it admin-dashboard bash
```

---

## 🖥️ 方案 B: 本地运行（不使用 Docker）

### 第一步：安装依赖服务

#### 1. 安装 PostgreSQL 16

```powershell
# 下载地址
https://www.postgresql.org/download/windows/

# 安装步骤
1. 运行安装程序
2. 安装目录: C:\Program Files\PostgreSQL\16
3. 端口: 5432
4. 超级用户密码: postgres
5. 勾选 pgAdmin 4
6. 完成安装
```

验证安装:
```powershell
psql --version
```

#### 2. 安装 MongoDB 7

```powershell
# 下载地址
https://www.mongodb.com/try/download/community

# 安装步骤
1. 运行 msi 安装程序
2. 选择 "Complete" 安装
3. 勾选 "Install MongoDB as a Service"
4. 完成安装
```

验证安装:
```powershell
mongod --version
```

#### 3. 安装 Redis 7

Windows 上推荐使用 WSL2 中的 Redis:

```powershell
# 启用 WSL
wsl --install

# 进入 WSL
wsl

# 安装 Redis
sudo apt-get update
sudo apt-get install redis-server

# 启动 Redis
redis-server
```

或者下载 Windows 版本: https://github.com/microsoftarchive/redis/releases

#### 4. 安装 Node.js 23

```powershell
# 下载地址
https://nodejs.org/

# 选择 LTS 版本 23.x
# 默认安装即可

# 验证
node --version
npm --version
```

### 第二步：创建数据库

打开 PostgreSQL 命令行:

```powershell
psql -U postgres
```

执行以下 SQL:

```sql
-- 创建用户
CREATE USER hermes WITH PASSWORD 'hermes123';

-- 创建数据库
CREATE DATABASE hermes_studio OWNER hermes;
CREATE DATABASE hermes_studio_ls OWNER hermes;
CREATE DATABASE hermes_studio_zs OWNER hermes;
CREATE DATABASE hermes_central OWNER hermes;

-- 赋予权限
ALTER USER hermes CREATEDB;
GRANT ALL PRIVILEGES ON DATABASE hermes_studio TO hermes;
GRANT ALL PRIVILEGES ON DATABASE hermes_studio_ls TO hermes;
GRANT ALL PRIVILEGES ON DATABASE hermes_studio_zs TO hermes;
GRANT ALL PRIVILEGES ON DATABASE hermes_central TO hermes;

-- 退出
\q
```

### 第三步：启动脚本

创建 `start-all.ps1`:

```powershell
# 管理员运行

Write-Host "🚀 启动 Hermes Studio 多实例系统" -ForegroundColor Green

# 1. 启动 PostgreSQL
Write-Host "📦 启动 PostgreSQL..." -ForegroundColor Cyan
Start-Service -Name postgresql-x64-16 -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. 启动 MongoDB
Write-Host "🍃 启动 MongoDB..." -ForegroundColor Cyan
Start-Service -Name MongoDB -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 3. 启动 Redis (WSL)
Write-Host "🔴 启动 Redis..." -ForegroundColor Cyan
# 需要在 WSL 中手动启动或使用 Windows Redis

Write-Host "✅ 所有数据库服务已启动" -ForegroundColor Green
Write-Host ""
Write-Host "下一步: 在多个 PowerShell 窗口中运行以下命令" -ForegroundColor Yellow
Write-Host ""
Write-Host "窗口 1 - 超级管理员实例 (端口 6060):" -ForegroundColor Cyan
Write-Host "cd hermes-studio" -ForegroundColor White
Write-Host "`$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio'" -ForegroundColor White
Write-Host "`$env:PORT = 6060" -ForegroundColor White
Write-Host "`$env:INSTANCE_NAME = 'super'" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "窗口 2 - LS 实例 (端口 6061):" -ForegroundColor Cyan
Write-Host "cd hermes-studio" -ForegroundColor White
Write-Host "`$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_ls'" -ForegroundColor White
Write-Host "`$env:PORT = 6061" -ForegroundColor White
Write-Host "`$env:INSTANCE_NAME = 'ls'" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "窗口 3 - ZS 实例 (端口 6062):" -ForegroundColor Cyan
Write-Host "cd hermes-studio" -ForegroundColor White
Write-Host "`$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_zs'" -ForegroundColor White
Write-Host "`$env:PORT = 6062" -ForegroundColor White
Write-Host "`$env:INSTANCE_NAME = 'zs'" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "窗口 4 - 中央管理面板 (端口 5000):" -ForegroundColor Cyan
Write-Host "cd admin-dashboard" -ForegroundColor White
Write-Host "`$env:MONGODB_URI = 'mongodb://admin:admin123@localhost:27017/hermes_central?authSource=admin'" -ForegroundColor White
Write-Host "`$env:REDIS_URL = 'redis://:redis123@localhost:6379'" -ForegroundColor White
Write-Host "`$env:PORT = 5000" -ForegroundColor White
Write-Host "npm run dev" -ForegroundColor White
```

运行启动脚本:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\start-all.ps1
```

### 第四步：启动各个服务

打开 4 个 PowerShell 窗口，分别运行:

**窗口 1 - 超级管理员实例**
```powershell
cd D:\path\to\hermes-studio
$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio'
$env:PORT = 6060
$env:INSTANCE_NAME = 'super'
$env:CENTRAL_ADMIN_ENABLED = 1
$env:CENTRAL_ADMIN_URL = 'http://localhost:5000'
$env:CENTRAL_ADMIN_SECRET = 'central_admin_webhook_secret'
npm install
npm run dev
```

**窗口 2 - LS 实例**
```powershell
cd D:\path\to\hermes-studio
$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_ls'
$env:PORT = 6061
$env:INSTANCE_NAME = 'ls'
$env:CENTRAL_ADMIN_ENABLED = 1
$env:CENTRAL_ADMIN_URL = 'http://localhost:5000'
$env:CENTRAL_ADMIN_SECRET = 'central_admin_webhook_secret'
npm run dev
```

**窗口 3 - ZS 实例**
```powershell
cd D:\path\to\hermes-studio
$env:DATABASE_URL = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_zs'
$env:PORT = 6062
$env:INSTANCE_NAME = 'zs'
$env:CENTRAL_ADMIN_ENABLED = 1
$env:CENTRAL_ADMIN_URL = 'http://localhost:5000'
$env:CENTRAL_ADMIN_SECRET = 'central_admin_webhook_secret'
npm run dev
```

**窗口 4 - 中央管理面板**
```powershell
cd D:\path\to\admin-dashboard
$env:NODE_ENV = 'development'
$env:PORT = 5000
$env:MONGODB_URI = 'mongodb://admin:admin123@localhost:27017/hermes_central?authSource=admin'
$env:REDIS_URL = 'redis://:redis123@localhost:6379'
$env:JWT_SECRET = 'admin_jwt_secret_jkl012opq'
$env:INSTANCE_SUPER_URL = 'http://localhost:6060'
$env:INSTANCE_LS_URL = 'http://localhost:6061'
$env:INSTANCE_ZS_URL = 'http://localhost:6062'
$env:INSTANCE_SUPER_DB = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio'
$env:INSTANCE_LS_DB = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_ls'
$env:INSTANCE_ZS_DB = 'postgresql://hermes:hermes123@localhost:5432/hermes_studio_zs'
npm install
npm run dev
```

### 第五步：访问服务

打开浏览器:

- 中央管理面板: http://localhost:5000
- 超级管理员: http://localhost:6060
- LS 实例: http://localhost:6061
- ZS 实例: http://localhost:6062

---

## 🔧 常见问题排查

### Q1: 端口已被占用

```powershell
# 查找占用端口的进程
Get-NetTCPConnection -LocalPort 6060 | Select ProcessName, OwningProcess

# 杀死进程
Stop-Process -Id <PID> -Force

# 或改用其他端口，修改 docker-compose.yml 或环境变量
```

### Q2: Docker 容器无法启动

```powershell
# 查看详细日志
docker-compose logs admin-dashboard

# 重新构建镜像
docker-compose build --no-cache
docker-compose up -d
```

### Q3: 数据库连接失败

```powershell
# 检查数据库是否运行
docker-compose ps postgres-super

# 测试连接
docker exec postgres-super psql -U hermes -c "SELECT 1"

# 查看 PostgreSQL 日志
docker-compose logs postgres-super
```

### Q4: MongoDB 连接问题

```powershell
# 检查 MongoDB 是否运行
docker-compose ps mongo-central

# 查看日志
docker-compose logs mongo-central

# 重启 MongoDB
docker restart mongo-central
```

### Q5: 页面无法访问

```powershell
# 检查 Nginx
docker-compose ps nginx

# 检查 hosts 文件
Get-Content C:\Windows\System32\drivers\etc\hosts | findstr xx.local

# ���新 DNS
ipconfig /flushdns
```

---

## 📊 验证部署

### Docker 方案验证

```powershell
# 1. 检查所有容器运行状态
docker-compose ps
# 预期输出: 所有容器状态都是 "Up"

# 2. 检查端口监听
Get-NetTCPConnection -State Listen | findstr "6060|6061|6062|5000|27017|6379"

# 3. 测试 HTTP 连接
(Invoke-WebRequest -Uri "http://admin.xx.local:5000" -UseBasicParsing).StatusCode
# 预期: 200

# 4. 查看服务日志
docker-compose logs --tail=50
```

### 本地方案验证

```powershell
# 1. 检查 PostgreSQL 服务
Get-Service postgresql-x64-16 | Select Status

# 2. 检查 MongoDB 服务
Get-Service MongoDB | Select Status

# 3. 测试数据库连接
psql -U hermes -d hermes_studio -h localhost -c "SELECT 1"

# 4. 检查 Node.js 进程
Get-Process node
```

---

## 🛑 停止和清理

### Docker 方案

```powershell
# 停止所有容器
docker-compose down

# 停止并删除数据（谨慎！）
docker-compose down -v

# 完全清理
docker-compose down -v --remove-orphans
```

### 本地方案

```powershell
# 停止 PostgreSQL
Stop-Service postgresql-x64-16

# 停止 MongoDB
Stop-Service MongoDB

# 杀死 Node.js 进程
Stop-Process -Name node -Force
```

---

## 📝 下一步

### 在本地测试以下功能

- ✅ 在中央面板创建新用户
- ✅ 验证用户自动同步到 3 个实例
- ✅ 测试在不同实例创建会话
- ✅ 监控 Token 消耗
- ✅ 查看操作日志
- ✅ 设置用户配额

### 迁移到服务器

1. 修改 hosts 为真实域名
2. 生成新的 JWT 密钥
3. 配置 HTTPS/SSL 证书
4. 修改数据库密码
5. 配置自动备份
6. 设置监控告警

---

## 🆘 获取帮助

查看详细文档: [./docs](./docs)
查看日志文件: `docker-compose logs`

常见问题解答: [./docs/FAQ.md](./docs/FAQ.md)

---

## 📄 许可证

BSL-1.1
