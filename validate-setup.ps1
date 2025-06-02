# ================================================================================
# Validation Script for GitHub Actions CI/CD Setup
# ================================================================================
# Ten skrypt sprawdza czy wszystkie elementy pipeline CI/CD są poprawnie skonfigurowane

param(
    [switch]$Detailed,
    [string]$DockerHubUsername = "your-dockerhub-username"
)

Write-Host "🔍 Walidacja konfiguracji GitHub Actions CI/CD" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

$errors = @()
$warnings = @()
$success = @()

# Sprawdzenie struktury plików
Write-Host "`n📁 Sprawdzanie struktury plików..." -ForegroundColor Yellow

$requiredFiles = @(
    "main.cpp",
    "CMakeLists.txt", 
    "Dockerfile",
    ".github/workflows/build-and-publish.yml",
    "README.md",
    "README-CICD.md",
    "CHECKLIST.md",
    "QUICK_START.md"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        $success += "✅ $file - istnieje"
    } else {
        $errors += "❌ $file - brak pliku"
    }
}

# Sprawdzenie workflow YAML
Write-Host "`n🔧 Sprawdzanie konfiguracji workflow..." -ForegroundColor Yellow

$workflowPath = ".github/workflows/build-and-publish.yml"
if (Test-Path $workflowPath) {
    $workflowContent = Get-Content $workflowPath -Raw
    
    # Sprawdzenie kluczowych elementów
    $requiredElements = @{
        "docker/build-push-action@v5" = "Docker Build Action"
        "docker/setup-buildx-action@v3" = "Docker Buildx Setup"
        "aquasecurity/trivy-action@master" = "Trivy CVE Scanner"
        "linux/amd64,linux/arm64" = "Multi-arch platforms"
        "type=registry,ref=" = "Registry cache configuration"
        "DOCKERHUB_USERNAME" = "DockerHub username secret"
        "DOCKERHUB_TOKEN" = "DockerHub token secret"
    }
    
    foreach ($element in $requiredElements.GetEnumerator()) {
        if ($workflowContent -match [regex]::Escape($element.Key)) {
            $success += "✅ $($element.Value) - skonfigurowany"
        } else {
            $errors += "❌ $($element.Value) - brak konfiguracji"
        }
    }
    
    # Sprawdzenie placeholdera username
    if ($workflowContent -match "your-dockerhub-username") {
        $warnings += "⚠️  CACHE_REPO zawiera placeholder - zmień na swoją nazwę użytkownika"
    } else {
        $success += "✅ CACHE_REPO - zaktualizowany"
    }
    
} else {
    $errors += "❌ Workflow YAML - plik nie istnieje"
}

# Sprawdzenie Dockerfile
Write-Host "`n🐳 Sprawdzanie Dockerfile..." -ForegroundColor Yellow

if (Test-Path "Dockerfile") {
    $dockerfileContent = Get-Content "Dockerfile" -Raw
    
    $dockerRequirements = @{
        "ARG TARGETPLATFORM" = "Multi-arch support"
        "FROM scratch" = "Minimal base image"
        "LABEL org.opencontainers.image" = "OCI metadata"
        "EXPOSE 3000" = "Port exposure"
    }
    
    foreach ($req in $dockerRequirements.GetEnumerator()) {
        if ($dockerfileContent -match [regex]::Escape($req.Key)) {
            $success += "✅ Dockerfile: $($req.Value)"
        } else {
            $warnings += "⚠️  Dockerfile: brak $($req.Value)"
        }
    }
} else {
    $errors += "❌ Dockerfile - nie istnieje"
}

# Sprawdzenie repozytorium Git
Write-Host "`n📦 Sprawdzanie konfiguracji Git..." -ForegroundColor Yellow

try {
    $gitRemote = git remote get-url origin 2>$null
    if ($gitRemote) {
        $success += "✅ Git remote - skonfigurowany: $gitRemote"
        
        if ($gitRemote -match "github.com") {
            $success += "✅ GitHub repository - wykryty"
        } else {
            $warnings += "⚠️  Repository nie jest hostowany na GitHub"
        }
    } else {
        $warnings += "⚠️  Git remote - nie skonfigurowany"
    }
} catch {
    $warnings += "⚠️  Git - nie dostępny lub nie zainicjalizowany"
}

# Podsumowanie
Write-Host "`n📊 PODSUMOWANIE WALIDACJI" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

Write-Host "`n✅ SUKCES ($($success.Count)):" -ForegroundColor Green
$success | ForEach-Object { Write-Host "  $_" -ForegroundColor Green }

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  OSTRZEŻENIA ($($warnings.Count)):" -ForegroundColor Yellow
    $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

if ($errors.Count -gt 0) {
    Write-Host "`n❌ BŁĘDY ($($errors.Count)):" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

# Status końcowy
Write-Host "`n🎯 STATUS:" -ForegroundColor Cyan
if ($errors.Count -eq 0) {
    if ($warnings.Count -eq 0) {
        Write-Host "🎉 GOTOWY DO URUCHOMIENIA!" -ForegroundColor Green
        Write-Host "Pipeline CI/CD jest w pełni skonfigurowany i gotowy do użycia." -ForegroundColor Green
    } else {
        Write-Host "⚡ PRAWIE GOTOWY" -ForegroundColor Yellow
        Write-Host "Pipeline będzie działać, ale zaleca się naprawienie ostrzeżeń." -ForegroundColor Yellow
    }
} else {
    Write-Host "🚫 WYMAGA NAPRAWY" -ForegroundColor Red
    Write-Host "Napraw błędy przed uruchomieniem pipeline." -ForegroundColor Red
}

# Następne kroki
Write-Host "`n📋 NASTĘPNE KROKI:" -ForegroundColor Cyan
Write-Host "1. Dodaj secrets do GitHub: DOCKERHUB_USERNAME, DOCKERHUB_TOKEN" -ForegroundColor White
Write-Host "2. Utwórz publiczne repo 'buildcache' w DockerHub" -ForegroundColor White
Write-Host "3. Zaktualizuj CACHE_REPO w workflow na swoją nazwę użytkownika" -ForegroundColor White
Write-Host "4. Wykonaj push do main lub utwórz tag aby uruchomić pipeline" -ForegroundColor White

if ($Detailed) {
    Write-Host "`n📖 SZCZEGÓŁOWE INFORMACJE:" -ForegroundColor Cyan
    Write-Host "- Workflow triggers: push (main/master), tags (v*.*.*), PR, manual" -ForegroundColor Gray
    Write-Host "- Platforms: linux/amd64, linux/arm64" -ForegroundColor Gray
    Write-Host "- Cache: DockerHub registry cache z trybem 'max'" -ForegroundColor Gray
    Write-Host "- Security: Trivy CVE scanning z blokowaniem Critical/High" -ForegroundColor Gray
    Write-Host "- Registry: GitHub Container Registry (ghcr.io)" -ForegroundColor Gray
}

# Zwróć kod wyjścia
if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
