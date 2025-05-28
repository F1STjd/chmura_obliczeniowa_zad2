## Zadanie 2
## GitHub Actions CI/CD Pipeline

### Opis Workflow

Projekt zawiera kompletny pipeline CI/CD w pliku `.github/workflows/docker-pipeline.yml`, który automatyzuje:

1. **Budowanie wieloarchitektoniczne** - obrazy dla `linux/amd64` i `linux/arm64`
2. **Cache management** - wykorzystanie DockerHub jako registry cache z eksportem/importem
3. **Skanowanie bezpieczeństwa** - analiza CVE przy użyciu Trivy
4. **Publikacja** - push do GitHub Container Registry (ghcr.io)

### Strategia Tagowania

- **`latest`** - najnowsza stabilna wersja z głównej gałęzi
- **`<branch>-<sha>`** - unikalny tag dla każdego commit'a umożliwiający rollback
- **Cache tags** - `<dockerhub-username>/project-cache:{arch}-cache-{sha}`

### Wybór Skanera Bezpieczeństwa

**Trivy** został wybrany zamiast Docker Scout z następujących powodów:
- Prostsza konfiguracja i integracja z GitHub Actions
- Darmowe skanowanie bez wymagania dodatkowych kont
- Lepsze wsparcie dla formatu SARIF
- Dokumentacja: https://github.com/aquasecurity/trivy-action

### Wymagane Sekrety Repository

Aby workflow działał poprawnie, należy skonfigurować następujące sekrety w ustawieniach repozytorium GitHub (`Settings > Secrets and variables > Actions`):

#### Obowiązkowe sekrety:

1. **`GHCR_TOKEN`**
   - Typ: Personal Access Token (classic)
   - Uprawnienia: `write:packages`, `read:packages`
   - Instrukcja: GitHub Settings > Developer settings > Personal access tokens

2. **`DOCKERHUB_USERNAME`**
   - Typ: String
   - Wartość: Nazwa użytkownika DockerHub (do cache registry)

3. **`DOCKERHUB_TOKEN`**
   - Typ: String  
   - Wartość: Access Token z DockerHub
   - Instrukcja: DockerHub > Account Settings > Security > New Access Token

#### Opcjonalne sekrety:

4. **`SSH_PRIVATE_KEY`** (tylko jeśli potrzebna konfiguracja SSH)
   - Typ: SSH Private Key
   - Wartość: Klucz prywatny SSH (zawartość pliku `~/.ssh/id_rsa`)

### Uruchomienie Pipeline

Pipeline uruchamia się automatycznie przy:
- Push do gałęzi `main`, `master`, `develop`
- Utworzeniu Pull Request do `main`/`master`
- Ręcznym uruchomieniu przez GitHub UI (`workflow_dispatch`)

### Bezpieczeństwo

- Pipeline odrzuci publikację obrazu jeśli wykryje CVE o poziomie `CRITICAL` lub `HIGH`
- Wyniki skanowania są automatycznie uploading do GitHub Security tab
- Używa najnowszych wersji Actions z pinned tag'ami dla bezpieczeństwa