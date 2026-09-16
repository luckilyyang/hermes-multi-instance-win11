# 常见问题与解答

## 问题 1: Docker 容器无法启动

### 症状
- `docker-compose up -d` 后容器立即停止
- 查看日志显示错误

### 解决方案

```powershell
# 查看详细日志
docker-compose logs admin-dashboard

# 重建镜像
docker-compose build --no-cache

# 重新启动
docker-compose up -d
```

---

## 问题 2: 端口已被占用

### 症状
- 启动时报错: "Address already in use"
- 某个服务无法连接

### 解决方案

```powershell
# 找到占用端口的进程
Get-NetTCPConnection -LocalPort 6060 | Select ProcessName, OwningProcess

# 关闭该进程
Stop-Process -Id <PID> -Force

# 或者修改 docker-compose.yml 中的端口映射
# 例如将 6060:6060 改为 6063:6060
```

---

## 问题 3: 无法访问 admin.xx.local

### 症状
- 浏览器显示 "无法访问"
- 连接被拒绝

### 解决方案

```powershell
# 检查 hosts 文件
Get-Content C:\Windows\System32\drivers\etc\hosts | findstr "admin.xx.local"

# 如果没有，以管理员身份编辑 hosts 文件并添加:
# 127.0.0.1 admin.xx.local

# 刷新 DNS 缓存
ipconfig /flushdns

# 验证 DNS 解析
[System.Net.Dns]::GetHostAddresses("admin.xx.local")

# 检查 Nginx 是否运行
docker-compose ps nginx

# 检查 Nginx 日志
docker-compose logs nginx
```

---

## 问题 4: MongoDB 连接失败

### 症状
- 管理面板无法加载数据
- 错误日志显示 MongoDB 连接错误

### 解决方案

```powershell
# 检查 MongoDB 容器
docker-compose ps mongo-central

# 查看 MongoDB 日志
docker-compose logs mongo-central

# 进入 MongoDB 容器
docker exec -it mongo-central mongosh admin -u admin -p admin123

# 在 MongoDB 中验证数据库
show dbs
use hermes_central
show collections

# 退出
exit

# 如果需要重新初始化
docker-compose down -v
docker-compose up -d
```

---

## 问题 5: PostgreSQL 数据库连接问题

### 症状
- Hermes Studio 实例无法启动
- 错误: "connection refused"

### 解决方案

```powershell
# 检查 PostgreSQL 容器
docker-compose ps postgres-super postgres-ls postgres-zs

# 测试连接
docker exec postgres-super psql -U hermes -d hermes_studio -c "SELECT 1"

# 查看 PostgreSQL 日志
docker-compose logs postgres-super

# 进入 PostgreSQL 命令行
docker exec -it postgres-super psql -U hermes -d hermes_studio

# 查看表
\dt

# 查看用户
\du

# 退出
\q
```

---

## 问题 6: Redis 连接问题

### 症状
- 管理面板响应缓慢
- Session 丢失

### 解决方案

```powershell
# 检查 Redis 容器
docker-compose ps redis-central

# 测试 Redis 连接
docker exec redis-central redis-cli -a redis123 ping
# 应该返回: PONG

# 查看 Redis 日志
docker-compose logs redis-central

# 清空 Redis 缓存
docker exec redis-central redis-cli -a redis123 FLUSHALL

# 进入 Redis CLI
docker exec -it redis-central redis-cli -a redis123
# 命令: KEYS *, INFO, FLUSHALL
# 退出: exit
```

---

## 问题 7: Hermes Studio 实例无法创建会话

### 症状
- 点击发送消息后无响应
- 错误日志显示数据库操作失败

### 解决方案

```powershell
# 查看实例日志
docker-compose logs -f studio-super
docker-compose logs -f studio-ls
docker-compose logs -f studio-zs

# 验证数据库连接
docker exec postgres-super psql -U hermes -d hermes_studio -c \
  "SELECT * FROM sessions LIMIT 5"

# 检查数据库权限
docker exec postgres-super psql -U hermes -d hermes_studio -c \
  "SELECT * FROM information_schema.role_table_grants WHERE grantee='hermes'"

# 重启实例
docker-compose restart studio-super
```

---

## 问题 8: 如何备份数据

### 备份 PostgreSQL

```powershell
# 备份 super 实例
docker exec postgres-super pg_dump -U hermes -d hermes_studio > backup-super-$(Get-Date -Format yyyyMMdd).sql

# 备份 ls 实例
docker exec postgres-ls pg_dump -U hermes -d hermes_studio > backup-ls-$(Get-Date -Format yyyyMMdd).sql

# 备份 zs 实例
docker exec postgres-zs pg_dump -U hermes -d hermes_studio > backup-zs-$(Get-Date -Format yyyyMMdd).sql
```

### 备份 MongoDB

```powershell
# 备份中央数据库
docker exec mongo-central mongodump --authenticationDatabase admin -u admin -p admin123 -d hermes_central -o /tmp/mongodb-backup

# 从容器复制到本地
docker cp mongo-central:/tmp/mongodb-backup ./mongodb-backup-$(Get-Date -Format yyyyMMdd)
```

---

## 问题 9: 如何恢复数据

### 恢复 PostgreSQL

```powershell
# 恢复 super 实例
docker exec -i postgres-super psql -U hermes -d hermes_studio < backup-super-20240101.sql
```

### 恢复 MongoDB

```powershell
# 将备份复制到容器
docker cp ./mongodb-backup mongo-central:/tmp/

# 恢复
docker exec mongo-central mongorestore --authenticationDatabase admin -u admin -p admin123 /tmp/mongodb-backup
```

---

## 问题 10: 如何清除所有数据重新开始

### ⚠️ 警告：这会删除所有数据！

```powershell
# 停止所有容器并删除数据
docker-compose down -v --remove-orphans

# 删除 Docker 镜像（可选）
docker-compose down -v --remove-orphans --rmi all

# 重新启动
.\scripts\start.ps1
```

---

## 问题 11: 如何升级服务

```powershell
# 获取最新镜像
docker-compose pull

# 停止当前运行的容器
docker-compose down

# 用新镜像启动
docker-compose up -d

# 查看升级进度
docker-compose logs -f
```

---

## 问题 12: 性能调优

### 增加 Docker 资源限制

编辑 `docker-compose.yml`，为每个服务添加资源限制：

```yaml
services:
  admin-dashboard:
    # ... 其他配置 ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### 优化 PostgreSQL

```powershell
# 进入 PostgreSQL
docker exec -it postgres-super psql -U hermes -d hermes_studio

# 分析表
ANALYZE;

# 查看表大小
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# 退出
\q
```

---

## 问题 13: 本地方案 (不使用 Docker) 常见问题

### PostgreSQL 服务无法启动

```powershell
# 检查服务状态
Get-Service postgresql-x64-16

# 启动服务
Start-Service postgresql-x64-16

# 查看事件日志
Get-EventLog -LogName Application -Source "PostgreSQL" -Newest 10
```

### Redis 连接失败

```powershell
# 在 WSL 中启动 Redis
wsl redis-server

# 或者使用 Windows Redis 版本
redis-server

# 测试连接
redis-cli ping
# 返回: PONG
```

---

## 获取更多帮助

- 查看完整文档: [README.md](../README.md)
- 查看 Docker 日志: `docker-compose logs`
- 查看特定服务日志: `docker-compose logs service-name`
- 查看实时日志: `docker-compose logs -f`
- GitHub Issues: https://github.com/luckilyyang/hermes-multi-instance-win11/issues
