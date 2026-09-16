# Windows PowerShell 启动脚本
# 以管理员身份运行此脚本

Write-Host "" -ForegroundColor Green
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║     🚀 Hermes Studio 多实例中央管理系统启动脚本           ║" -ForegroundColor Green
Write-Host "║     Windows 11 本地部署                                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# 检查 Docker
Write-Host "📦 检查 Docker 状态..." -ForegroundColor Cyan
$dockerCheck = docker --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker 已安装: $dockerCheck" -ForegroundColor Green
} else {
    Write-Host "❌ Docker 未安装或未运行，请先安装 Docker Desktop" -ForegroundColor Red
    exit 1
}

# 检查 Docker Compose
$composeCheck = docker-compose --version 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker Compose 已安装: $composeCheck" -ForegroundColor Green
} else {
    Write-Host "❌ Docker Compose 未安装" -ForegroundColor Red
    exit 1
}

# 检查 hosts 文件
Write-Host ""
Write-Host "🔍 检查 hosts 文件配置..." -ForegroundColor Cyan
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsPath -Raw

$required = @(
    "super.xx.local",
    "ls.xx.local",
    "zs.xx.local",
    "admin.xx.local"
)

$missing = @()
foreach ($host in $required) {
    if ($hostsContent -match $host) {
        Write-Host "✅ $host 已配置" -ForegroundColor Green
    } else {
        Write-Host "❌ $host 未配置" -ForegroundColor Yellow
        $missing += $host
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️  需要配置以下域名到 hosts 文件:" -ForegroundColor Yellow
    foreach ($host in $missing) {
        Write-Host "   127.0.0.1 $host" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "编辑文件: C:\\Windows\\System32\\drivers\\etc\\hosts (需要管理员权限)" -ForegroundColor Yellow
    Write-Host "然后运行: ipconfig /flushdns" -ForegroundColor Yellow
}

# 创建 .env 文件
Write-Host ""
Write-Host "⚙️  检查环境文件..." -ForegroundColor Cyan
if (-Not (Test-Path ".env")) {
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "✅ 已从 .env.example 创建 .env 文件" -ForegroundColor Green
    } else {
        Write-Host "❌ 找不到 .env.example 文件" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ .env 文件已存在" -ForegroundColor Green
}

# 检查 docker-compose.yml
if (-Not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ 找不到 docker-compose.yml 文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ docker-compose.yml 文件已存在" -ForegroundColor Green

# 启动服务
Write-Host ""
Write-Host "🐳 启动 Docker Compose 服务..." -ForegroundColor Cyan
Write-Host "这可能需要 5-10 分钟（首次启动需要下载镜像）" -ForegroundColor Yellow
Write-Host ""

docker-compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker Compose 启动失败" -ForegroundColor Red
    Write-Host "请运行: docker-compose logs" -ForegroundColor Yellow
    exit 1
}

# 等待服务启动
Write-Host "⏳ 等待服务启动 (30 秒)..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# 检查容器状态
Write-Host ""
Write-Host "🔍 检查容器状态..." -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    🎉 启动完成！                          ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📍 访问地址:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🌐 中央管理面板:" -ForegroundColor White
Write-Host "     URL: http://admin.xx.local:5000" -ForegroundColor Yellow
Write-Host "     用户名: superadmin" -ForegroundColor Yellow
Write-Host "     密码: admin123" -ForegroundColor Yellow
Write-Host ""
Write-Host "  👤 超级管理员实例:" -ForegroundColor White
Write-Host "     URL: http://super.xx.local" -ForegroundColor Yellow
Write-Host "     用户名: admin" -ForegroundColor Yellow
Write-Host "     密码: admin123" -ForegroundColor Yellow
Write-Host ""
Write-Host "  👤 LS 管理员实例:" -ForegroundColor White
Write-Host "     URL: http://ls.xx.local" -ForegroundColor Yellow
Write-Host "     用户名: admin" -ForegroundColor Yellow
Write-Host "     密码: admin123" -ForegroundColor Yellow
Write-Host ""
Write-Host "  👤 ZS 管理员实例:" -ForegroundColor White
Write-Host "     URL: http://zs.xx.local" -ForegroundColor Yellow
Write-Host "     用户名: admin" -ForegroundColor Yellow
Write-Host "     密码: admin123" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  首次登录后请立即修改密码！" -ForegroundColor Red
Write-Host ""
Write-Host "💡 常用命令:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  查看所有容器:" -ForegroundColor White
Write-Host "    docker-compose ps" -ForegroundColor Gray
Write-Host ""
Write-Host "  查看日志:" -ForegroundColor White
Write-Host "    docker-compose logs -f admin-dashboard" -ForegroundColor Gray
Write-Host "    docker-compose logs -f studio-super" -ForegroundColor Gray
Write-Host ""
Write-Host "  停止服务:" -ForegroundColor White
Write-Host "    docker-compose down" -ForegroundColor Gray
Write-Host ""
Write-Host "  删除所有数据（谨慎！）:" -ForegroundColor White
Write-Host "    docker-compose down -v" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 查看完整文档: README.md" -ForegroundColor Cyan
Write-Host ""
