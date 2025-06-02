# Zadanie 2 - GitHub Actions CI/CD Pipeline

## Autor: Konrad Nowak

> **Uwaga**: To jest rozszerzenie "Zadania 1" o kompletny pipeline CI/CD wykorzystujący GitHub Actions dla budowania, testowania i publikowania obrazów Docker w architekturze multi-platform.

## CZĘŚĆ OBOWIĄZKOWA
https://github.com/F1STjd/chmura_obliczeniowa_zad1

---

## CZĘŚĆ ROZSZERZONA - GitHub Actions CI/CD Pipeline

### 1. Opis Pipeline'u

Opracowany workflow GitHub Actions realizuje kompletny proces CI/CD dla aplikacji pogodowej:

#### Główne funkcjonalności:
- **Multi-architektura**: Budowanie obrazów dla `linux/amd64` i `linux/arm64`
- **Cache optymalizacja**: Wykorzystanie DockerHub jako backend dla cache warstw budowania
- **Skanowanie CVE**: Automatyczne wykrywanie podatności przy użyciu Trivy
- **Publikacja**: Automatyczne wysyłanie obrazów do GitHub Container Registry (ghcr.io)
- **Inteligentne tagowanie**: Różne strategie tagów w zależności od typu push'a

### 2. Architektura Workflow

#### Workflow składa się z następujących kroków:

1. **Checkout kodu** - Pobranie kodu źródłowego
2. **Setup Docker Buildx** - Konfiguracja multi-platform budowania
3. **Logowanie do registrów** - DockerHub (cache) i GHCR (publikacja)
4. **Generowanie metadanych** - Automatyczne tagi i labels
5. **Build z cache** - Budowanie obrazu z wykorzystaniem cache
6. **Skanowanie CVE** - Test podatności za pomocą Trivy
7. **Publikacja** - Push obrazu do GHCR (tylko po pomyślnym skanowaniu)

### 3. Strategia Tagowania

#### Logika tagów obrazów:
- **Push do `main`/`master`**: 
  - `latest`
  - `main-{sha}` (unikalny identyfikator commit)
- **Tagi wersji (`v1.0.0`)**:
  - `1.0.0` (pełna wersja)
  - `1.0` (major.minor)
  - `1` (major)
  - `latest`
- **Pull Requests**: `pr-{number}`
- **Inne gałęzie**: `{branch-name}-{sha}`

### 4. Strategia Cache

#### Konfiguracja cache Docker:
- **Backend**: DockerHub Registry
- **Format**: `{dockerhub_username}/buildcache:buildcache-{ref}`
- **Tryb**: `max` (pełne cachowanie wszystkich warstw)
- **Optymalizacja**: Osobny cache dla każdej gałęzi/tagu
- **Fallback**: Cache z gałęzi `main` jako backup

#### Przykład cache key:
```
knewroo/buildcache:buildcache-main        # dla gałęzi main
knewroo/buildcache:buildcache-v1.0.0      # dla tagu v1.0.0
knewroo/buildcache:buildcache-feature     # dla gałęzi feature
```

### 5. Skanowanie Podatności CVE

#### Wybór narzędzia: Trivy
**Uzasadnienie wyboru Trivy:**
- ✅ Darmowe i open-source
- ✅ Oficjalne GitHub Action dostępne
- ✅ Doskonała obsługa obrazów statycznie skompilowanych
- ✅ Szybkie skanowanie z obsługą cache
- ✅ Integracja z GitHub Security tab
- ✅ Obsługa SARIF format dla raportowania

**Alternatywa Docker Scout:**
- ❌ Wymaga płatnej subskrypcji dla zaawansowanych funkcji
- ❌ Brak oficjalnego GitHub Action
- ❌ Ograniczenia w darmowej wersji

#### Konfiguracja skanowania:
- **Poziomy blokujące**: `CRITICAL`, `HIGH`
- **Architektura**: Skanowanie tylko `linux/amd64` (binarka identyczna na obu architekturach)
- **Format raportów**: SARIF (upload do GitHub Security)
- **Działanie**: Blokowanie publikacji przy wykryciu podatności krytycznych

### 6. Konfiguracja Secrets

Aby workflow działał poprawnie, należy dodać następujące secrets w ustawieniach repozytorium GitHub:

#### Wymagane secrets:
```
DOCKERHUB_USERNAME - Nazwa użytkownika DockerHub (dla cache)
DOCKERHUB_TOKEN    - Token dostępu DockerHub (dla cache)
```

#### Opcjonalne secrets:
```
GHCR_TOKEN - Dodatkowy token dla GHCR (jeśli GITHUB_TOKEN niewystarczający)
```

#### Instrukcja dodawania secrets:
1. Idź do **Settings** → **Secrets and variables** → **Actions**
2. Kliknij **New repository secret**
3. Dodaj każdy secret osobno:
   - `DOCKERHUB_USERNAME`: Twoja nazwa użytkownika DockerHub
   - `DOCKERHUB_TOKEN`: Token utworzony w DockerHub (Account Settings → Security)

### 7. Uruchamianie Pipeline

#### Automatyczne wyzwalacze:
- **Push do `main`/`master`** - Budowanie i publikacja z tagiem `latest`
- **Utworzenie tagu `v*.*.*`** - Budowanie wersji release
- **Pull Request** - Tylko budowanie (bez publikacji)

#### Ręczne uruchomienie:
1. Idź do zakładki **Actions** w repozytorium
2. Wybierz workflow **"Build and Publish Multi-Arch Docker Image"**
3. Kliknij **"Run workflow"**
4. Wybierz gałąź i kliknij **"Run workflow"**

### 8. Monitorowanie i Debugowanie

#### Logi i monitoring:
- **GitHub Actions tab**: Szczegółowe logi każdego kroku
- **Security tab**: Raporty skanowania Trivy
- **Packages**: Lista opublikowanych obrazów w GHCR

#### Typowe problemy i rozwiązania:
- **Błąd autoryzacji GHCR**: Sprawdź uprawnienia `packages: write`
- **Błąd cache DockerHub**: Sprawdź poprawność DOCKERHUB_* secrets
- **Długi czas budowania**: Cache może nie działać - sprawdź DockerHub connectivity
- **Błędy CVE**: Sprawdź Security tab dla szczegółów podatności

### 9. Użycie Opublikowanych Obrazów

#### Pobranie i uruchomienie:
```bash
# Pobranie najnowszej wersji
docker pull ghcr.io/your-username/your-repo:latest

# Uruchomienie aplikacji
docker run -d -p 3000:3000 --name weather-app ghcr.io/your-username/your-repo:latest

# Sprawdzenie logów
docker logs weather-app

# Aplikacja dostępna na: http://localhost:3000
```

#### Multi-architektura:
```bash
# Docker automatycznie wybierze odpowiednią architekturę
docker pull ghcr.io/your-username/your-repo:latest  # arm64 na Apple Silicon, amd64 na Intel

# Explicit platform selection
docker pull --platform linux/amd64 ghcr.io/your-username/your-repo:latest
docker pull --platform linux/arm64 ghcr.io/your-username/your-repo:latest
```

### 10. Wnioski i Korzyści

#### Osiągnięte cele:
- ✅ **Automatyzacja**: Pełny pipeline bez ręcznej interwencji
- ✅ **Multi-platform**: Obsługa ARM64 i AMD64 architektur
- ✅ **Bezpieczeństwo**: Automatyczne skanowanie CVE z blokowaniem
- ✅ **Optymalizacja**: Intelligent cache znacznie przyspiesza budowanie
- ✅ **Monitoring**: Integracja z GitHub Security i przejrzyste logi
- ✅ **Skalowalność**: Łatwe dodawanie nowych architektur i platform

#### Metryki wydajności:
- **Pierwszy build**: ~3-5 minut (bez cache)
- **Kolejne buildy**: ~1-2 minuty (z cache)
- **Rozmiar obrazu**: 1.29MB (optymalizowany)
- **Czas skanowania**: ~30 sekund
- **Obsługiwane architektury**: 2 (AMD64, ARM64)