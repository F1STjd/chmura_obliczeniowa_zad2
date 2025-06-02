# 🚀 Quick Start Guide - GitHub Actions CI/CD

## ⚡ 5-minutowa konfiguracja

### 1. Przygotowanie repozytorium GitHub

```bash
# Sklonuj repozytorium
git clone https://github.com/username/weather-app.git
cd weather-app

# Upewnij się, że masz wszystkie pliki
ls -la
# Powinieneś zobaczyć: main.cpp, CMakeLists.txt, Dockerfile, .github/workflows/
```

### 2. Konfiguracja DockerHub (wymagane dla cache)

1. **Utwórz konto DockerHub** (jeśli nie masz): https://hub.docker.com
2. **Utwórz publiczne repozytorium** o nazwie `buildcache`
3. **Wygeneruj Personal Access Token**:
   - Idź do: Account Settings → Security → New Access Token
   - Nazwa: "GitHub Actions CI/CD"  
   - Uprawnienia: Read, Write, Delete
   - **Skopiuj token** (będzie pokazany tylko raz!)

### 3. Dodaj secrets do GitHub

```bash
# Opcja A: Przez GitHub CLI
gh secret set DOCKERHUB_USERNAME --body "your_dockerhub_username"
gh secret set DOCKERHUB_TOKEN --body "dckr_pat_your_token_here"

# Opcja B: Przez interface GitHub
# 1. Idź do Settings → Secrets and variables → Actions
# 2. Kliknij "New repository secret"
# 3. Dodaj oba secrets osobno
```

### 4. Testuj pipeline

```bash
# Opcja A: Push do main (wyzwoli automatycznie)
git add .
git commit -m "feat: enable CI/CD pipeline"
git push origin main

# Opcja B: Utwórz tag wersji
git tag v1.0.0
git push origin v1.0.0

# Opcja C: Ręczne uruchomienie
# Idź do GitHub → Actions → "Build and Publish Multi-Arch Docker Image" → Run workflow
```

### 5. Monitoruj wykonanie

1. **GitHub Actions**: Sprawdź postęp w zakładce Actions
2. **Logi**: Kliknij na job aby zobaczyć szczegółowe logi
3. **Wynik**: Po sukcesie obraz będzie dostępny w Packages

## ✅ Checklist weryfikacji

- [ ] Secrets DOCKERHUB_USERNAME i DOCKERHUB_TOKEN dodane
- [ ] Repozytorium DockerHub/buildcache utworzone jako public
- [ ] Pipeline wykonał się bez błędów
- [ ] Obraz pojawił się w GitHub Packages
- [ ] Skanowanie CVE przeszło pomyślnie
- [ ] Obie architektury (amd64, arm64) są dostępne

## 🎯 Oczekiwane rezultaty

Po udanej konfiguracji zobaczysz:

```bash
# Dostępne obrazy w GHCR
ghcr.io/username/repo:latest
ghcr.io/username/repo:main-abc1234
ghcr.io/username/repo:v1.0.0

# Każdy obraz wspiera multi-arch
docker pull ghcr.io/username/repo:latest  # automatycznie wybierze architekturę
docker pull --platform linux/amd64 ghcr.io/username/repo:latest
docker pull --platform linux/arm64 ghcr.io/username/repo:latest

# Test aplikacji
docker run -p 3000:3000 ghcr.io/username/repo:latest
# Otwórz: http://localhost:3000
```

## 🔧 Rozwiązywanie problemów

### Problem: "Error: buildx failed with authentication"
```bash
# Sprawdź secrets
gh secret list | grep DOCKERHUB

# Test logowania
echo $DOCKERHUB_TOKEN | docker login --username $DOCKERHUB_USERNAME --password-stdin
```

### Problem: "Error: cache export failed"
```bash
# Upewnij się, że repozytorium buildcache istnieje i jest public
# Sprawdź w DockerHub: https://hub.docker.com/r/username/buildcache
```

### Problem: Długi czas budowania
```bash
# Sprawdź w logach cache hit rate
# Szukaj linii: "CACHED [stage ...] RUN ..."
# Powinno być widoczne wykorzystanie cache dla większości kroków
```

## 📞 Wsparcie

- **Dokumentacja techniczna**: README-CICD.md
- **GitHub Issues**: https://github.com/username/repo/issues  
- **Docker Buildx docs**: https://docs.docker.com/buildx/
- **GitHub Actions docs**: https://docs.github.com/en/actions

---

**🎉 Gratulacje!** Twój pipeline CI/CD jest gotowy do użycia. Każdy push będzie automatycznie budował, testował i publikował obrazy Docker w multi-arch.
