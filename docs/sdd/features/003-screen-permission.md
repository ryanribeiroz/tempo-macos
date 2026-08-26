# TEMPO-F003 — Permissão de tela sem repetição

- Status: `implemented`
- Versão: `1.0.2`
- Atualizado em: `2026-08-25`

## Contexto

Uma verificação legada retornava negação mesmo com o Tempo habilitado, e a assinatura ad hoc mudava a identidade reconhecida pelo sistema entre builds.

## Requirements

- `TEMPO-F003-R01` — IF screen recording is already authorized THEN Tempo SHALL start without requesting the same permission again.
- `TEMPO-F003-R02` — WHEN a new local build is installed THEN Tempo SHALL keep a stable designated requirement.
- `TEMPO-F003-R03` — IF ScreenCaptureKit denies access THEN Tempo SHALL explain how to open the correct System Settings page.

## Design

- A tentativa real com ScreenCaptureKit é a fonte de verdade.
- `CGPreflightScreenCaptureAccess` e `CGRequestScreenCaptureAccess` não participam mais do fluxo.
- O empacotamento assina com requisito explícito baseado no bundle identifier.

## Tasks

- [x] Remover preflight legado. _Requirements: R01_
- [x] Mapear erros de permissão. _Requirements: R03_
- [x] Estabilizar designated requirement. _Requirements: R02_

## Implementation record

### O que foi implementado

Verificação moderna de acesso e assinatura local estável.

### Como foi implementado

`CaptureSession.verifyAccess` consulta `SCShareableContent`. O script usa `designated => identifier "com.local.tempo"`.

### Arquivos alterados

- `Sources/Tempo/AppModel.swift`
- `Sources/Tempo/CaptureSession.swift`
- `Scripts/package-app.sh`
- `Resources/Info.plist`

### Harnesses e fixtures

Permissão real exige teste interativo; o fluxo de estado usa `AppModelHarness` para eventos que não dependem de TCC.

### Verificação

- Busca confirma ausência das APIs legadas.
- `codesign -d -r-` confirma requisito estável.

### Limitações conhecidas

A primeira instalação sempre depende da decisão do usuário nos Ajustes do Sistema.
