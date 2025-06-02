# ================================================================================
# Pipeline Monitoring Script - GitHub Actions CI/CD
# ================================================================================
# Skrypt do monitorowania statusu pipeline CI/CD w czasie rzeczywistym

param(
    [switch]$Follow,
    [int]$RefreshInterval = 30
)

Write-Host "🔍 Monitor GitHub Actions CI/CD Pipeline" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Informacje o repozytorium
$repoUrl = "https://github.com/F1STjd/chmura_obliczeniowa_zad2"
$actionsUrl = "$repoUrl/actions"
$packagesUrl = "$repoUrl/pkgs/container/chmura_obliczeniowa_zad2"

Write-Host "`n📦 Repository: $repoUrl" -ForegroundColor White
Write-Host "🔄 Actions: $actionsUrl" -ForegroundColor White
Write-Host "📦 Packages: $packagesUrl" -ForegroundColor White

# Sprawdzenie czy Git CLI jest dostępne
try {
    $currentCommit = git rev-parse HEAD
    $currentBranch = git branch --show-current
    Write-Host "`n📍 Current commit: $currentCommit" -ForegroundColor Yellow
    Write-Host "🌿 Current branch: $currentBranch" -ForegroundColor Yellow
} catch {
    Write-Host "`n⚠️  Git CLI not available - showing general info only" -ForegroundColor Yellow
}

# Sprawdzenie czy GitHub CLI jest dostępne
$ghAvailable = $false
try {
    gh --version | Out-Null
    $ghAvailable = $true
    Write-Host "`n✅ GitHub CLI available - detailed monitoring enabled" -ForegroundColor Green
} catch {
    Write-Host "`n⚠️  GitHub CLI not available - manual monitoring required" -ForegroundColor Yellow
}

Write-Host "`n🎯 Pipeline Status:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

if ($ghAvailable) {
    try {
        Write-Host "`n🔄 Fetching latest workflow runs..." -ForegroundColor Yellow
        $runs = gh run list --limit 5 --json status,conclusion,name,createdAt,url | ConvertFrom-Json
        
        if ($runs.Count -gt 0) {
            Write-Host "`n📊 Recent workflow runs:" -ForegroundColor Cyan
            foreach ($run in $runs) {
                $status = $run.status
                $conclusion = $run.conclusion
                $name = $run.name
                $created = $run.createdAt
                $url = $run.url
                
                $statusIcon = switch ($status) {
                    "in_progress" { "🔄" }
                    "queued" { "⏳" }
                    "completed" { 
                        switch ($conclusion) {
                            "success" { "✅" }
                            "failure" { "❌" }
                            "cancelled" { "⚠️" }
                            default { "❓" }
                        }
                    }
                    default { "❓" }
                }
                
                $statusColor = switch ($status) {
                    "in_progress" { "Yellow" }
                    "queued" { "Cyan" }
                    "completed" { 
                        switch ($conclusion) {
                            "success" { "Green" }
                            "failure" { "Red" }
                            "cancelled" { "Yellow" }
                            default { "Gray" }
                        }
                    }
                    default { "Gray" }
                }
                
                Write-Host "$statusIcon [$status/$conclusion] $name" -ForegroundColor $statusColor
                Write-Host "   📅 Created: $created" -ForegroundColor Gray
                Write-Host "   🔗 URL: $url" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "No workflow runs found." -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Error fetching workflow status: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Manual monitoring URLs:" -ForegroundColor White
    Write-Host "• Actions: $actionsUrl" -ForegroundColor Blue
    Write-Host "• Latest run: $actionsUrl/runs" -ForegroundColor Blue
}

# Informacje o oczekiwanych krokach pipeline
Write-Host "`n📋 Expected Pipeline Steps (12 total):" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

$steps = @(
    "1. ✅ Checkout repository",
    "2. ✅ Set up Docker Buildx", 
    "3. ✅ Log in to DockerHub (for cache)",
    "4. ✅ Log in to GitHub Container Registry",
    "5. ✅ Extract metadata",
    "6. 🔄 Build Docker image (with cache)",
    "7. 🔄 Build single-arch image for CVE scanning",
    "8. 🔍 Run Trivy vulnerability scanner",
    "9. 📊 Upload Trivy scan results to GitHub Security",
    "10. 🛡️ Check Trivy scan results",
    "11. 🚀 Build and push multi-arch Docker image",
    "12. 🎉 Image published successfully"
)

foreach ($step in $steps) {
    Write-Host "  $step" -ForegroundColor White
}

Write-Host "`n⏱️ Expected timing:" -ForegroundColor Cyan
Write-Host "• Cold cache: 8-12 minutes" -ForegroundColor Gray
Write-Host "• Warm cache: 3-5 minutes" -ForegroundColor Gray
Write-Host "• CVE scanning: 1-2 minutes" -ForegroundColor Gray

Write-Host "`n🔍 What to watch for:" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host "✅ Build succeeds for both linux/amd64 and linux/arm64" -ForegroundColor Green
Write-Host "✅ Cache is successfully stored in konradnowakpollub/buildcache" -ForegroundColor Green
Write-Host "✅ CVE scan finds no CRITICAL or HIGH vulnerabilities" -ForegroundColor Green
Write-Host "✅ Image is published to ghcr.io/f1stjd/chmura_obliczeniowa_zad2" -ForegroundColor Green

Write-Host "`n⚠️ Potential issues:" -ForegroundColor Yellow
Write-Host "• DockerHub authentication failure - check secrets" -ForegroundColor Red
Write-Host "• Multi-arch build timeout - check cache" -ForegroundColor Red
Write-Host "• CVE vulnerabilities found - check base image" -ForegroundColor Red
Write-Host "• Registry push failure - check permissions" -ForegroundColor Red

# Monitoring loop jeśli Follow jest włączone
if ($Follow -and $ghAvailable) {
    Write-Host "`n🔄 Following mode enabled (refresh every $RefreshInterval seconds)" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    
    while ($true) {
        Start-Sleep -Seconds $RefreshInterval
        Clear-Host
        Write-Host "🔄 Auto-refreshed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
        
        try {
            $latestRun = gh run list --limit 1 --json status,conclusion,name,createdAt,url | ConvertFrom-Json | Select-Object -First 1
            
            if ($latestRun) {
                $status = $latestRun.status
                $conclusion = $latestRun.conclusion
                
                Write-Host "`n🎯 Latest run status: $status" -ForegroundColor Cyan
                if ($conclusion) {
                    Write-Host "🏁 Conclusion: $conclusion" -ForegroundColor $(if ($conclusion -eq "success") { "Green" } else { "Red" })
                }
                
                if ($status -eq "completed") {
                    Write-Host "`n🎉 Pipeline completed!" -ForegroundColor Green
                    
                    if ($conclusion -eq "success") {
                        Write-Host "✅ Success! Check your published image at:" -ForegroundColor Green
                        Write-Host "$packagesUrl" -ForegroundColor Blue
                    } else {
                        Write-Host "❌ Pipeline failed. Check logs at:" -ForegroundColor Red
                        Write-Host "$($latestRun.url)" -ForegroundColor Blue
                    }
                    break
                }
            }
        } catch {
            Write-Host "❌ Error during monitoring: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host "`n📖 Quick commands:" -ForegroundColor Cyan
Write-Host "• Monitor: .\monitor-pipeline.ps1 -Follow" -ForegroundColor Gray
Write-Host "• Check runs: gh run list" -ForegroundColor Gray
Write-Host "• View logs: gh run view --log" -ForegroundColor Gray
Write-Host "• Re-run: gh run rerun" -ForegroundColor Gray
