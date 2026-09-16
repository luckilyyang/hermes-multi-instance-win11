# Windows PowerShell 日志查看脚本
# 使用: .\logs.ps1 [service_name]

param(
    [string]$Service = "admin-dashboard"
)

if (-Not $Service) {
    Write-Host "使用方式: .\logs.ps1 [service_name]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "可用的服务:" -ForegroundColor Cyan
    Write-Host "  - admin-dashboard" -ForegroundColor White
    Write-Host "  - studio-super" -ForegroundColor White
    Write-Host "  - studio-ls" -ForegroundColor White
    Write-Host "  - studio-zs" -ForegroundColor White
    Write-Host "  - postgres-super" -ForegroundColor White
    Write-Host "  - postgres-ls" -ForegroundColor White
    Write-Host "  - postgres-zs" -ForegroundColor White
    Write-Host "  - mongo-central" -ForegroundColor White
    Write-Host "  - redis-central" -ForegroundColor White
    Write-Host "  - nginx" -ForegroundColor White
    exit 1
}

Write-Host "📋 查看 $Service 的日志..." -ForegroundColor Cyan
Write-Host "(按 Ctrl+C 停止)" -ForegroundColor Yellow
Write-Host ""

docker-compose logs -f $Service
