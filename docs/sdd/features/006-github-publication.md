# TEMPO-F006 — Publicação do projeto no GitHub

- Status: `in-progress`
- Versão: `1.1.0`
- Atualizado em: `2026-08-26`

## Contexto

O código do Tempo precisa ficar disponível no repositório remoto `ryanribeiroz/tempo-macos`, preservando a estrutura SDD e sem enviar caches, vídeos ou artefatos locais.

## Requirements

- `TEMPO-F006-R01` — WHEN the project is published THEN the repository SHALL contain source code, tests, harnesses, fixtures and SDD documentation at its root.
- `TEMPO-F006-R02` — WHEN files are staged THEN Git SHALL exclude build caches, temporary files, exported videos and packaged artifacts.
- `TEMPO-F006-R03` — WHEN the initial publication completes THEN the local `main` branch SHALL track `origin/main` at `https://github.com/ryanribeiroz/tempo-macos.git`.
- `TEMPO-F006-R04` — BEFORE publication THEN the standard test harness SHALL complete with zero failures.

## Design

- `work/Tempo` será a raiz do repositório, evitando publicar as pastas intermediárias do workspace.
- `.gitignore` protege caches e artefatos; `.gitattributes` normaliza arquivos de texto.
- A publicação usa Git nativo e a autenticação já configurada no macOS.
- O branch inicial é `main` e o remoto se chama `origin`.

### Decisões

- `TEMPO-F006-D01` — O bundle compilado não será versionado; releases devem anexar binários separadamente quando necessário.
- `TEMPO-F006-D02` — Nenhuma licença foi presumida porque o proprietário não especificou uma.

## Tasks

- [x] Criar regras de ignore e normalização. _Requirements: R02_
- [ ] Executar `Scripts/test.sh`. _Requirements: R04_
- [ ] Inicializar Git, revisar o staging e criar o commit inicial. _Requirements: R01, R02_
- [ ] Configurar `origin` e publicar `main`. _Requirements: R03_
- [ ] Verificar o commit remoto e completar este registro.

## Implementation record

Será concluído depois da confirmação do push remoto.
