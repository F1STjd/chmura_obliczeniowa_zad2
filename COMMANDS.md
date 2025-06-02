# 🛠️ Commands Reference - GitHub Actions CI/CD

## 🚀 Szybkie uruchomienie

### Konfiguracja pipeline
```bash
# 1. Klonowanie repozytorium
git clone https://github.com/username/weather-app.git
cd weather-app

# 2. Dodanie secrets do GitHub (przez CLI)
gh secret set DOCKERHUB_USERNAME --body "your_dockerhub_username"
gh secret set DOCKERHUB_TOKEN --body "dckr_pat_your_token"

# 3. Aktualizacja CACHE_REPO w workflow
sed -i 's/your-dockerhub-username/actual_username/g' .github/workflows/build-and-publish.yml

# 4. Uruchomienie pipeline
git add .
git commit -m "feat: configure CI/CD pipeline"
git push origin main
```

## 🔧 Testowanie lokalne

### Docker build tests
```bash
# Test standardowego build
docker build -t weather-app:test .

# Test multi-arch (wymaga buildx)
docker buildx create --name multiarch --use
docker buildx build --platform linux/amd64,linux/arm64 -t weather-app:multi .

# Test z cache
docker buildx build --cache-to type=local,dest=./cache-dir .
docker buildx build --cache-from type=local,src=./cache-dir .
```

### Testowanie aplikacji
```bash
# Uruchomienie lokalnie
docker run -d -p 3000:3000 --name weather-test weather-app:test

# Test API
curl http://localhost:3000

# Test z parametrami
curl "http://localhost:3000/?country=Poland&city=Warsaw"

# Sprawdzenie logów
docker logs weather-test

# Cleanup
docker stop weather-test && docker rm weather-test
```

## 🔍 Monitorowanie CI/CD

### GitHub Actions
```bash
# Status workflow przez CLI
gh run list --workflow="build-and-publish.yml"

# Szczegóły konkretnego run
gh run view RUN_ID

# Logi konkretnego kroku
gh run view RUN_ID --log
```

### Registry checks
```bash
# Sprawdzenie obrazów w GHCR
gh api /user/packages/container/REPO_NAME/versions

# Pull i test opublikowanego obrazu
docker pull ghcr.io/username/repo:latest
docker run -p 3000:3000 ghcr.io/username/repo:latest

# Multi-arch inspection
docker buildx imagetools inspect ghcr.io/username/repo:latest
```

## 🔐 Secrets management

### Dodawanie secrets
```bash
# Przez GitHub CLI
gh secret set SECRET_NAME --body "secret_value"

# Lista secrets
gh secret list

# Usuwanie secret
gh secret delete SECRET_NAME
```

### DockerHub token management
```bash
# Test logowania
echo $DOCKERHUB_TOKEN | docker login --username $DOCKERHUB_USERNAME --password-stdin

# Test push do cache repo
docker tag weather-app:test $DOCKERHUB_USERNAME/buildcache:test
docker push $DOCKERHUB_USERNAME/buildcache:test
```

## 📊 Cache management

### Cache operations
```bash
# Sprawdzenie cache w DockerHub
docker pull $DOCKERHUB_USERNAME/buildcache:buildcache-main

# Czyszczenie cache lokalnego
docker buildx prune --all

# Build z wymuszonym cache refresh
docker buildx build --no-cache --platform linux/amd64,linux/arm64 .
```

### Cache debugging
```bash
# Sprawdzenie użycia cache w build
docker buildx build --progress=plain --platform linux/amd64 . 2>&1 | grep -i cache

# Analiza warstw obrazu
docker history ghcr.io/username/repo:latest
```

## 🔬 Security scanning

### Trivy local testing
```bash
# Instalacja Trivy (Linux/macOS)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Skanowanie lokalnego obrazu
trivy image weather-app:test

# Skanowanie tylko wysokich podatności
trivy image --severity HIGH,CRITICAL weather-app:test

# Export do SARIF
trivy image --format sarif --output trivy-results.sarif weather-app:test
```

### Manual CVE checks
```bash
# Sprawdzenie konkretnych CVE
trivy image --ignore-unfixed --severity HIGH,CRITICAL weather-app:test

# Porównanie z poprzednią wersją
trivy image ghcr.io/username/repo:v1.0.0
trivy image ghcr.io/username/repo:latest
```

## 🏷️ Version management

### Semantic versioning
```bash
# Tworzenie wersji release
git tag v1.0.0
git push origin v1.0.0

# Pre-release
git tag v1.1.0-beta.1
git push origin v1.1.0-beta.1

# Patch release
git tag v1.0.1
git push origin v1.0.1
```

### Tag management
```bash
# Lista tagów
git tag -l

# Usuwanie tagu lokalnie i zdalnie
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

## 🔄 Workflow management

### Manual trigger
```bash
# Ręczne uruchomienie workflow
gh workflow run build-and-publish.yml

# Uruchomienie na konkretnej gałęzi
gh workflow run build-and-publish.yml --ref feature-branch
```

### Workflow debugging
```bash
# Download artifacts
gh run download RUN_ID

# Sprawdzenie statusu workflow
gh workflow view build-and-publish.yml

# Lista wszystkich workflow
gh workflow list
```

## 🧹 Cleanup commands

### Local cleanup
```bash
# Usunięcie wszystkich obrazów
docker rmi $(docker images -q)

# Usunięcie buildx builder
docker buildx rm multiarch

# Czyszczenie cache
docker system prune -a --volumes
```

### Registry cleanup
```bash
# Usunięcie starych obrazów z GHCR (przez API)
# Note: Wymaga odpowiednich uprawnień
gh api --method DELETE /user/packages/container/REPO_NAME/versions/VERSION_ID
```

## 📈 Performance optimization

### Build optimization
```bash
# Build z maksymalnym wykorzystaniem CPU
docker buildx build --platform linux/amd64,linux/arm64 --cache-to type=registry,ref=cache:latest,mode=max .

# Równoległy build
docker buildx build --platform linux/amd64,linux/arm64 --cache-from type=registry,ref=cache:latest .
```

### Cache optimization
```bash
# Export cache do zewnętrznego registry
docker buildx build --cache-to type=registry,ref=registry.com/cache:latest,mode=max .

# Import z wielu źródeł cache
docker buildx build \
  --cache-from type=registry,ref=cache:main \
  --cache-from type=registry,ref=cache:develop \
  --cache-from type=local,src=./cache .
```

---

## 🆘 Emergency procedures

### Pipeline failing
```bash
# 1. Sprawdź logi
gh run view --log

# 2. Test lokalnie
docker build .

# 3. Sprawdź secrets
gh secret list

# 4. Re-run failed job
gh run rerun RUN_ID --failed
```

### Registry issues
```bash
# 1. Test connectivity
docker login ghcr.io
docker login

# 2. Manual push
docker tag weather-app:test ghcr.io/username/repo:manual
docker push ghcr.io/username/repo:manual

# 3. Sprawdź uprawnienia
gh api /user/packages
```

### Security scan failures
```bash
# 1. Local Trivy test
trivy image weather-app:test

# 2. Ignore specific CVE (jeśli false positive)
echo "CVE-2024-XXXXX" > .trivyignore

# 3. Update base image
# Zaktualizuj FROM alpine:3.21 na nowszą wersję
```
