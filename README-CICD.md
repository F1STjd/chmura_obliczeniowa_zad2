## Analiza workflow

### Szczegółowy przebieg kroków

#### STEP 1-2: Przygotowanie środowiska
```yaml
- name: Checkout repository
  uses: actions/checkout@v4

- name: Set up Docker Buildx  
  uses: docker/setup-buildx-action@v3
  with:
    driver-opts: network=host
```  
**Cel**: Pobranie kodu i konfiguracja multi-arch buildingu

#### STEP 3-4: Autoryzacja
```yaml
- name: Log in to DockerHub (for cache)
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```  
**Cel**: Dostęp do cache registry i target registry

#### STEP 5: Generowanie metadanych
```yaml
- name: Extract metadata
  id: meta
  uses: docker/metadata-action@v5
  with:
    images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    tags: |
      type=semver,pattern={{version}}
      type=ref,event=branch,suffix=-{{sha}}
      type=raw,value=latest,enable={{is_default_branch}}
```  
**Cel**: Automatyczne generowanie tagów i labels

#### STEP 6-7: Build z cache
```yaml
- name: Build Docker image (with cache)
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64
    cache-from: type=registry,ref=${{ env.CACHE_REPO }}:buildcache-${{ github.ref_name }}
    cache-to: type=registry,ref=${{ env.CACHE_REPO }}:buildcache-${{ github.ref_name }},mode=max
```
**Czas wykonania**: 
- Pierwszy build: ~4-6 minut
- Z cache: ~1-2 minuty

**Cel**: Budowanie obrazu z maksymalnym wykorzystaniem cache

#### STEP 8-10: Skanowanie CVE
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image --severity CRITICAL,HIGH \
  --format json scan-image:latest | jq '[.Results[]?.Vulnerabilities // []] | add | length'
```  
**Cel**: Wykrywanie podatności bezpieczeństwa

#### STEP 11: Publikacja
```yaml
- name: Build and push multi-arch Docker image
  if: github.event_name != 'pull_request' && success()
  uses: docker/build-push-action@v5
  with:
    platforms: linux/amd64,linux/arm64
    push: true
```  
**Cel**: Publikacja obrazu do GHCR

### Matryca tagowania

| Trigger | Przykład | Tagi generowane |
|---------|----------|-----------------|
| Push to main | `git push origin main` | `latest`, `main-abc1234` |
| Tag semver | `git tag v1.2.3 && git push --tags` | `v1.2.3`, `1.2.3`, `1.2`, `1`, `latest` |
| Pull Request | `gh pr create` | `pr-123` |
| Feature branch | `git push origin feature/auth` | `feature-auth-abc1234` |
