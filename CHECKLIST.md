# ✅ Pre-deployment Checklist - GitHub Actions CI/CD

## 📋 Checklist przed uruchomieniem pipeline

### 🔧 Konfiguracja podstawowa

- [ ] **Repozytorium GitHub** skonfigurowane z kodem źródłowym
- [ ] **Konto DockerHub** utworzone (https://hub.docker.com)
- [ ] **Publiczne repozytorium `buildcache`** utworzone w DockerHub
- [ ] **Personal Access Token** wygenerowany w DockerHub z uprawnieniami Read/Write/Delete

### 🔐 GitHub Secrets

Dodaj w **Settings → Secrets and variables → Actions**:

- [ ] `DOCKERHUB_USERNAME` - nazwa użytkownika DockerHub
- [ ] `DOCKERHUB_TOKEN` - personal access token z DockerHub

### 📝 Pliki workflow

- [ ] **`.github/workflows/build-and-publish.yml`** istnieje
- [ ] **`CACHE_REPO`** w workflow zaktualizowany na własny (np. `username/buildcache`)
- [ ] **Uprawnienia** w workflow: `contents: read`, `packages: write`, `security-events: write`

### 🐳 Dockerfile

- [ ] **Multi-arch support** - Dockerfile obsługuje budowanie dla różnych architektur
- [ ] **Statyczne linkowanie** - aplikacja kompilowana statycznie
- [ ] **Minimalne size** - obraz bazowy `FROM scratch`

### 🧪 Testy lokalne (opcjonalne)

```bash
# Test logowania DockerHub
echo $DOCKERHUB_TOKEN | docker login --username $DOCKERHUB_USERNAME --password-stdin

# Test multi-arch build lokalnie
docker buildx create --name multiarch --use
docker buildx build --platform linux/amd64,linux/arm64 -t test:latest .

# Test aplikacji lokalnie
docker build -t weather-test .
docker run -p 3000:3000 weather-test
# Otwórz: http://localhost:3000
```

### 🚀 Pierwszego uruchomienie

#### Opcja A: Push do main
```bash
git add .
git commit -m "feat: implement GitHub Actions CI/CD pipeline"
git push origin main
```

#### Opcja B: Tag wersji
```bash
git tag v1.0.0
git push origin v1.0.0
```

#### Opcja C: Ręczne uruchomienie
1. Idź do **GitHub → Actions**
2. Wybierz **"Build and Publish Multi-Arch Docker Image"**
3. Kliknij **"Run workflow"**

### 📊 Monitorowanie wykonania

- [ ] **GitHub Actions** - sprawdź logi w zakładce Actions
- [ ] **Security tab** - sprawdź wyniki skanowania Trivy
- [ ] **Packages** - sprawdź czy obraz został opublikowany w GHCR
- [ ] **DockerHub** - sprawdź czy cache został zapisany

### 🎯 Oczekiwane rezultaty

Po pomyślnym wykonaniu pipeline:

```bash
# Dostępne obrazy (przykład)
ghcr.io/username/repo:latest
ghcr.io/username/repo:main-abc1234
ghcr.io/username/repo:v1.0.0

# Test działania
docker run -p 3000:3000 ghcr.io/username/repo:latest
curl http://localhost:3000  # Powinien zwrócić HTML z formularzem
```

### ⚡ Metryki wydajności

| Etap | Pierwszy build | Z cache | Cel |
|------|----------------|---------|-----|
| Setup + Checkout | ~30s | ~30s | <45s |
| Multi-arch build | 5-8min | 1-2min | <3min |
| CVE scan | ~45s | ~30s | <60s |
| Push registry | ~60s | ~45s | <90s |
| **TOTAL** | **7-10min** | **3-4min** | **<5min** |

### 🔍 Rozwiązywanie problemów

#### Błąd: "buildx failed with authentication"
```bash
# Sprawdź secrets
gh secret list | grep DOCKERHUB

# Sprawdź token
docker login --username=$DOCKERHUB_USERNAME --password=$DOCKERHUB_TOKEN
```

#### Błąd: "cache export failed"
- Sprawdź czy repozytorium `buildcache` istnieje w DockerHub
- Upewnij się, że repozytorium jest **publiczne**
- Sprawdź czy nazwa w `CACHE_REPO` jest poprawna

#### Błąd: "CVE scan failed"
- Sprawdź czy obraz został zbudowany poprawnie
- Sprawdź logi Trivy w Actions
- Ewentualnie wyłącz czasowo skanowanie (zmień `exit-code: '0'`)

#### Długi czas budowania
- Sprawdź cache hit rate w logach
- Szukaj linii `CACHED [stage ...] RUN ...`
- Upewnij się, że cache jest zapisywany do DockerHub

### 📞 Dokumentacja pomocnicza

- **README-CICD.md** - szczegółowa dokumentacja techniczna
- **QUICK_START.md** - instrukcje szybkiego startu
- **.env.example** - przykład konfiguracji zmiennych
- **GitHub Actions docs**: https://docs.github.com/en/actions
- **Docker Buildx docs**: https://docs.docker.com/buildx/

---

## 🎉 Status po zakończeniu

- [ ] Pipeline wykonał się pomyślnie ✅
- [ ] Obraz opublikowany w GHCR ✅  
- [ ] Skanowanie CVE przeszło bez błędów ✅
- [ ] Cache działa poprawnie ✅
- [ ] Aplikacja dostępna na porcie 3000 ✅
- [ ] Multi-arch support potwierdzone ✅

**Gratulacje! Twój GitHub Actions CI/CD pipeline jest w pełni funkcjonalny!** 🚀
