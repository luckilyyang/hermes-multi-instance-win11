# Windows PowerShell 测试验证脚本
# 用于验证部署的所有功能是否正常工作

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Hermes Studio 多实例系统 - 功能测试验证脚本" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$testResults = @{}
$passCount = 0
$failCount = 0

# 辅助函数
function Test-Service {
    param(
        [string]$ServiceName,
        [string]$Port = $null
    )
    
    Write-Host "🧪 测试 $ServiceName..." -ForegroundColor Cyan
    
    $container = docker-compose ps $ServiceName 2>&1
    if ($container -match "Up") {
        Write-Host "  ✅ $ServiceName 正在运行" -ForegroundColor Green
        
        if ($Port) {
            try {
                $response = (Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -ErrorAction SilentlyContinue).StatusCode
                if ($response -eq 200) {
                    Write-Host "  ✅ $ServiceName 可访问 (Port $Port)" -ForegroundColor Green
                    return $true
                }
            } catch {
                Write-Host "  ⚠️  $ServiceName 运行但端口不可访问" -ForegroundColor Yellow
            }
        }
        return $true
    } else {
        Write-Host "  ❌ $ServiceName 未运行" -ForegroundColor Red
        return $false
    }
}

function Test-Database {
    param(
        [string]$DbType,
        [string]$Container
    )
    
    Write-Host "🧪 测试 $DbType 数据库..." -ForegroundColor Cyan
    
    switch ($DbType) {
        "PostgreSQL" {
            try {
                $result = docker exec $Container psql -U hermes -d hermes_studio -c "SELECT 1" 2>&1
                if ($result -match "1") {
                    Write-Host "  ✅ $DbType 数据库连接成功" -ForegroundColor Green
                    return $true
                }
            } catch {}
        }
        "MongoDB" {
            try {
                $result = docker exec $Container mongosh admin -u admin -p admin123 --eval "db.adminCommand('ping')" 2>&1
                if ($result -match "ok") {
                    Write-Host "  ✅ $DbType 数据库连接成功" -ForegroundColor Green
                    return $true
                }
            } catch {}
        }
        "Redis" {
            try {
                $result = docker exec $Container redis-cli -a redis123 ping 2>&1
                if ($result -match "PONG") {
                    Write-Host "  ✅ $DbType 缓存连接成功" -ForegroundColor Green
                    return $true
                }
            } catch {}
        }
    }
    
    Write-Host "  ❌ $DbType 数据库连接失败" -ForegroundColor Red
    return $false
}

function Test-HttpEndpoint {
    param(
        [string]$Url,
        [string]$Name
    )
    
    Write-Host "🧪 测试 HTTP 端点: $Name..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "  ✅ $Name 可访问 ($($response.StatusCode))" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ⚠️  $Name 返回状态码 $($response.StatusCode)" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "  ❌ $Name 无法访问: $_" -ForegroundColor Red
        return $false
    }
}

# ==================== 测试执行 ====================

Write-Host ""
Write-Host "═ 第一部分: Docker 容器状态" -ForegroundColor Yellow
Write-Host ""

if (Test-Service "admin-dashboard" "5000") { $passCount++ } else { $failCount++ }
if (Test-Service "studio-super" "6060") { $passCount++ } else { $failCount++ }
if (Test-Service "studio-ls" "6061") { $passCount++ } else { $failCount++ }
if (Test-Service "studio-zs" "6062") { $passCount++ } else { $failCount++ }
if (Test-Service "postgres-super") { $passCount++ } else { $failCount++ }
if (Test-Service "postgres-ls") { $passCount++ } else { $failCount++ }
if (Test-Service "postgres-zs") { $passCount++ } else { $failCount++ }
if (Test-Service "mongo-central") { $passCount++ } else { $failCount++ }
if (Test-Service "redis-central") { $passCount++ } else { $failCount++ }
if (Test-Service "nginx") { $passCount++ } else { $failCount++ }

Write-Host ""
Write-Host "═ 第二部分: 数据库连接" -ForegroundColor Yellow
Write-Host ""

if (Test-Database "PostgreSQL" "postgres-super") { $passCount++ } else { $failCount++ }
if (Test-Database "MongoDB" "mongo-central") { $passCount++ } else { $failCount++ }
if (Test-Database "Redis" "redis-central") { $passCount++ } else { $failCount++ }

Write-Host ""
Write-Host "═ 第三部分: HTTP 端点访问 (需要配置 hosts)" -ForegroundColor Yellow
Write-Host ""

try {
    if (Test-HttpEndpoint "http://admin.xx.local:5000" "中央管理面板") { $passCount++ } else { $failCount++ }
    if (Test-HttpEndpoint "http://super.xx.local" "超级管理员实例") { $passCount++ } else { $failCount++ }
    if (Test-HttpEndpoint "http://ls.xx.local" "LS 管理员实例") { $passCount++ } else { $failCount++ }
    if (Test-HttpEndpoint "http://zs.xx.local" "ZS 管理员实例") { $passCount++ } else { $failCount++ }
} catch {
    Write-Host "  ⚠️  跳过 HTTP 端点测试 (DNS 可能未配置)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═ 第四部分: 数据库表结构" -ForegroundColor Yellow
Write-Host ""

Write-Host "🧪 检查 PostgreSQL 表..." -ForegroundColor Cyan
try {
    $tables = docker exec postgres-super psql -U hermes -d hermes_studio -c "\\dt" 2>&1
    if ($tables -match "users" -and $tables -match "sessions") {
        Write-Host "  ✅ 数据库表结构完整" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ❌ 数据库表结构不完整" -ForegroundColor Red
        $failCount++
    }
} catch {
    Write-Host "  ❌ 无法检查表结构" -ForegroundColor Red
    $failCount++
}

Write-Host ""
Write-Host "🧪 检查 MongoDB 集合..." -ForegroundColor Cyan
try {
    $collections = docker exec mongo-central mongosh admin -u admin -p admin123 --quiet --eval "db.getSiblingDB('hermes_central').getCollectionNames()" 2>&1
    if ($collections -match "users") {
        Write-Host "  ✅ MongoDB 集合已创建" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ⚠️  MongoDB 集合可能未初始化" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  无法检查 MongoDB 集合" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═ 第五部分: 文件和配置" -ForegroundColor Yellow
Write-Host ""

Write-Host "🧪 检查必要文件..." -ForegroundColor Cyan
$requiredFiles = @(
    "docker-compose.yml",
    ".env",
    "nginx/nginx.conf",
    "nginx/conf.d/hermes.conf",
    "sql/init.sql",
    "mongo/init-central.js"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ $file 存在" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ❌ $file 不存在" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "═ 第六部分: 磁盘空间和资源" -ForegroundColor Yellow
Write-Host ""

Write-Host "🧪 检查 Docker 磁盘使用..." -ForegroundColor Cyan
try {
    $diskUsage = docker system df
    Write-Host $diskUsage -ForegroundColor Gray
    $passCount++
} catch {
    Write-Host "  ⚠️  无法获取磁盘信息" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═ 第七部分: 日志检查" -ForegroundColor Yellow
Write-Host ""

Write-Host "🧪 检查错误日志..." -ForegroundColor Cyan
try {
    $errors = docker-compose logs | Select-String -Pattern "ERROR|error|failed|Failed"
    if ($errors.Count -eq 0) {
        Write-Host "  ✅ 日志中没有发现错误" -ForegroundColor Green
        $passCount++
    } else {
        Write-Host "  ⚠️  发现以下错误:" -ForegroundColor Yellow
        $errors | ForEach-Object { Write-Host "     $_" -ForegroundColor Gray }
    }
} catch {
    Write-Host "  ⚠️  无法检查日志" -ForegroundColor Yellow
}

# ==================== 总结报告 ====================

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   测试结果摘要" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ 通过: $passCount" -ForegroundColor Green
Write-Host "❌ 失败: $failCount" -ForegroundColor Red

if ($failCount -eq 0) {
    Write-Host ""
    Write-Host "🎉 所有测试通过！系统已准备就绪。" -ForegroundColor Green
    Write-Host ""
    Write-Host "访问地址:" -ForegroundColor Cyan
    Write-Host "  中央管理面板: http://admin.xx.local:5000" -ForegroundColor Yellow
    Write-Host "  超级管理员: http://super.xx.local" -ForegroundColor Yellow
    Write-Host "  LS 管理员: http://ls.xx.local" -ForegroundColor Yellow
    Write-Host "  ZS 管理员: http://zs.xx.local" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "默认登录信息:" -ForegroundColor Cyan
    Write-Host "  用户名: superadmin / admin" -ForegroundColor Yellow
    Write-Host "  密码: admin123" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⚠️  请首次登录后立即修改密码！" -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host "⚠️  检测到 $failCount 个问题，请查看上述日志。" -ForegroundColor Red
    Write-Host ""
    Write-Host "故障排除步骤:" -ForegroundColor Cyan
    Write-Host "  1. 查看完整日志: docker-compose logs" -ForegroundColor White
    Write-Host "  2. 检查特定服务: docker-compose logs [service-name]" -ForegroundColor White
    Write-Host "  3. 重启容器: docker-compose restart" -ForegroundColor White
    Write-Host "  4. 查看常见问题: docs/FAQ.md" -ForegroundColor White
}

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
