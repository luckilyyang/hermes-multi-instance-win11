# 服务器部署指南

在 Windows 11 本地测试完成后，可以按照本指南迁移到生产服务器。

## 目标架构

```
Internet
   |
   v
┌─────────────────────┐
│  Nginx 反向代理     │
│ (Let's Encrypt SSL) │
└──────────┬──────────┘
           |
    ┌──────┴────────┬──────────┬──────────┐
    v               v          v          v
 super.xx.com  ls.xx.com  zs.xx.com  admin.xx.com
    |               |          |          |
┌───┴────────┐ ┌───┴─────┐ ┌──┴───────┐ ┌──┴───────────┐
│  Instance1 │ │Instance2│ │Instance3│ │ AdminPanel  │
│  (6060)    │ │ (6060)  │ │ (6060)  │ │  (5000)     │
└───┬────────┘ └───┬─────┘ └──┬───────┘ └──┬───────────┘
    |              |          |          |
    └──────┬───────┴──────────┴──────────┘
           |
    ┌──────┴──────────┬────────────┬──────────┐
    v                 v            v          v
 PostgreSQL      MongoDB      Redis      Docker volumes
 (3 instances)                          (3 instances)
```

## 📋 前置要求

### 服务器规格
- **OS**: Ubuntu 20.04 LTS 或 22.04 LTS
- **CPU**: 8 核以上
- **RAM**: 32GB 以上
- **存储**: 500GB SSD 以上
- **带宽**: 100Mbps 以上

### 必要软件
- Docker 20.10+
- Docker Compose 2.0+
- Git
- OpenSSL (用于 SSL 证书)

## 🚀 部署步骤

### 第一步：基础环境配置

```bash
# 更新系统
sudo apt-get update && sudo apt-get upgrade -y

# 安装依赖
sudo apt-get install -y git curl wget openssl

# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 将当前用户加入 docker 组
sudo usermod -aG docker $USER
group docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

### 第二步：克隆项目并配置

```bash
# 克隆项目
git clone https://github.com/luckilyyang/hermes-multi-instance-win11.git
cd hermes-multi-instance-win11

# 生成安全的密钥
DB_PASSWORD=$(openssl rand -hex 16)
MONGO_PASSWORD=$(openssl rand -hex 16)
REDIS_PASSWORD=$(openssl rand -hex 16)
JWT_SUPER=$(openssl rand -hex 32)
JWT_LS=$(openssl rand -hex 32)
JWT_ZS=$(openssl rand -hex 32)
ADMIN_JWT=$(openssl rand -hex 32)
CENTRAL_SECRET=$(openssl rand -hex 32)

# 创建 .env 文件
cat > .env <<EOF
DB_PASSWORD=$DB_PASSWORD
MONGO_PASSWORD=$MONGO_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
JWT_SECRET_SUPER=$JWT_SUPER
JWT_SECRET_LS=$JWT_LS
JWT_SECRET_ZS=$JWT_ZS
ADMIN_JWT_SECRET=$ADMIN_JWT
CENTRAL_ADMIN_SECRET=$CENTRAL_SECRET
NODE_ENV=production
EOF

# 保存密钥到安全位置
echo "生成的密钥:" > /root/hermes-credentials.txt
echo "DB_PASSWORD=$DB_PASSWORD" >> /root/hermes-credentials.txt
echo "MONGO_PASSWORD=$MONGO_PASSWORD" >> /root/hermes-credentials.txt
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> /root/hermes-credentials.txt
echo "请妥善保管此文件！" >> /root/hermes-credentials.txt
chmod 600 /root/hermes-credentials.txt
```

### 第三步：配置 SSL 证书

#### 使用 Let's Encrypt 自动证书

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 生成证书（替换你的域名）
sudo certbot certonly --standalone -d super.xx.com -d ls.xx.com -d zs.xx.com -d admin.xx.com

# 复制证书到项目目录
sudo mkdir -p nginx/ssl
sudo cp /etc/letsencrypt/live/super.xx.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/super.xx.com/privkey.pem nginx/ssl/key.pem
sudo chown -R $USER:$USER nginx/ssl
```

#### 配置自动续期

```bash
# 创建续期脚本
sudo cat > /etc/letsencrypt/renewal-hooks/post/docker-reload.sh <<'EOF'
#!/bin/bash
cd /opt/hermes-multi-instance-win11
cp /etc/letsencrypt/live/super.xx.com/fullchain.pem nginx/ssl/cert.pem
cp /etc/letsencrypt/live/super.xx.com/privkey.pem nginx/ssl/key.pem
docker-compose restart nginx
EOF

sudo chmod +x /etc/letsencrypt/renewal-hooks/post/docker-reload.sh

# 测试续期
sudo certbot renew --dry-run
```

### 第四步：更新 Nginx 配置

编辑 `nginx/conf.d/hermes.conf`，添加 HTTPS 支持：

```nginx
# 重定向 HTTP 到 HTTPS
server {
    server_name admin.xx.com super.xx.com ls.xx.com zs.xx.com;
    listen 80;
    return 301 https://$server_name$request_uri;
}

# HTTPS 配置
server {
    server_name admin.xx.com;
    listen 443 ssl http2;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # ... 其他配置 ...
}
```

### 第五步：启动服务

```bash
# 启动所有服务
docker-compose up -d

# 等待初始化
sleep 30

# 检查状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 第六步：配置监控和日志

#### 设置日志轮转

```bash
sudo cat > /etc/logrotate.d/hermes-docker <<'EOF'
/opt/hermes-multi-instance-win11/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        docker-compose restart 2>/dev/null || true
    endscript
}
EOF
```

#### 设置容器自动重启

```bash
# 创建 systemd 服务
sudo cat > /etc/systemd/system/hermes-docker.service <<'EOF'
[Unit]
Description=Hermes Multi-Instance System
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/hermes-multi-instance-win11
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
RemainAfterExit=yes
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable hermes-docker.service
sudo systemctl start hermes-docker.service
```

### 第七步：备份策略

#### 数据库自动备份

```bash
# 创建备份脚本
cat > /opt/hermes-backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# 备份 PostgreSQL
for db in super ls zs; do
    docker exec postgres-$db pg_dump -U hermes -d hermes_studio | gzip > $BACKUP_DIR/postgres-$db-$DATE.sql.gz
done

# 备份 MongoDB
docker exec mongo-central mongodump -u admin -p $MONGO_PASSWORD --authenticationDatabase admin -d hermes_central --out /tmp/mongo-backup
docker cp mongo-central:/tmp/mongo-backup $BACKUP_DIR/mongo-$DATE
tar -czf $BACKUP_DIR/mongo-$DATE.tar.gz -C $BACKUP_DIR mongo-$DATE

# 删除 7 天前的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "备份完成: $DATE"
EOF

chmod +x /opt/hermes-backup.sh

# 添加定时任务 (每天 2 AM)
sudo crontab -e
# 添加: 0 2 * * * /opt/hermes-backup.sh
```

### 第八步：监控和告警

#### 安装 Prometheus 和 Grafana (可选)

```bash
# 为 docker-compose.yml 添加 Prometheus
cat >> docker-compose.yml <<'EOF'
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    networks:
      - hermes-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    networks:
      - hermes-network
EOF

docker-compose up -d
```

---

## 🔐 安全建议

### 防火墙配置

```bash
# 允许 HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 拒绝其他端口的外部访问
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
```

### 安全加固

```bash
# 禁用 SSH 密码登录
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 更新系统和依赖
sudo apt-get update && sudo apt-get upgrade -y

# 定期安全更新
sudo apt-get install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 📊 性能优化

### 调整 Docker 资源限制

编辑 `docker-compose.yml`：

```yaml
services:
  admin-dashboard:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
```

### PostgreSQL 性能调优

```sql
-- 连接到 PostgreSQL
docker exec -it postgres-super psql -U hermes -d hermes_studio

-- 运行分析
ANALYZE;

-- 检查索引状态
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

---

## ✅ 部署检查清单

- [ ] Docker 和 Docker Compose 已安装
- [ ] 项目代码已克隆
- [ ] 生成了安全的密钥
- [ ] 配置了 SSL 证书
- [ ] 更新了 Nginx 配置
- [ ] 所有容器都在运行
- [ ] 数据库初始化成功
- [ ] 可以访问管理面板
- [ ] 备份策略已配置
- [ ] 监控已启用
- [ ] 防火墙已配置
- [ ] 定期备份已启动

---

## 📞 生产环境支持

有问题？查看：
- 详细日志：`docker-compose logs`
- 系统监控：`docker stats`
- 备份验证：`ls -lh /opt/backups`
- GitHub Issues: https://github.com/luckilyyang/hermes-multi-instance-win11/issues
