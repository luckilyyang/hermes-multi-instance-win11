# Windows PowerShell 停止脚本

Write-Host ""
Write-Host "🛑 停止所有 Docker 容器..." -ForegroundColor Red
Write-Host ""

docker-compose down

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ 所有服务已停止" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ 停止失败" -ForegroundColor Red
}

Write-Host ""
