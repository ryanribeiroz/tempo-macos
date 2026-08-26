# TEMPO-F005 — Infraestrutura SDD, harness e fixtures

- Status: `implemented`
- Versão: `1.1.0`
- Atualizado em: `2026-08-25`

## Contexto

O projeto precisa preservar decisões e permitir mudanças futuras sem reler toda a base. Testes existentes também repetem preparação de eventos, imagens e diretórios.

## Requirements

- `TEMPO-F005-R01` — WHEN a feature is implemented THEN the project SHALL contain one concise MD describing requirements, design, tasks, implementation and verification.
- `TEMPO-F005-R02` — WHEN tests need macOS events or media data THEN they SHALL use shared harnesses and fixtures.
- `TEMPO-F005-R03` — WHEN a maintainer starts a task THEN the SDD index SHALL direct them to only the relevant documentation and code.
- `TEMPO-F005-R04` — WHEN validation runs THEN one command SHALL execute the standard test suite with workspace-safe caches.

## Design

- `docs/sdd/README.md` é a porta de entrada.
- Um MD por feature guarda as três fases SDD e o registro final.
- `Harness` expressa ações do produto; `Fixtures` cria dados.
- `Scripts/test.sh` padroniza o ambiente SwiftPM.
- `AGENTS.md` torna o processo obrigatório em trabalhos futuros.

### Decisões

- `TEMPO-F005-D01` — Um documento por feature foi escolhido em vez de vários documentos por fase para reduzir navegação e tokens.
- `TEMPO-F005-D02` — Features históricas foram documentadas retroativamente para formar uma linha de base útil.

## Tasks

- [x] Criar convenções, índice, arquitetura e template. _Requirements: R01, R03_
- [x] Criar harnesses e fixtures compartilhadas. _Requirements: R02_
- [x] Refatorar testes para o suporte compartilhado. _Requirements: R02_
- [x] Criar runner único. _Requirements: R04_
- [x] Executar testes e completar o registro.

## Implementation record

### O que foi implementado

- Regras persistentes em `AGENTS.md` no workspace e no projeto.
- Índice SDD, arquitetura, convenções, rastreabilidade e template.
- Um documento consolidado para cada feature existente.
- Harness para eventos e ciclo do `AppModel`.
- Fixtures para diretórios temporários e imagens determinísticas.
- Harness para criação e inspeção de pixel buffers.
- Runner único `Scripts/test.sh`.
- Empacotador reproduzível `Scripts/package-source.sh`.

### Como foi implementado

Os testes deixaram de publicar eventos e montar mídia diretamente. `AppModelHarness` traduz intenção de teste em eventos do `NSWorkspace`; `VideoFrameFixture` e `PixelBufferHarness` escondem preparação de bytes e Core Video. O índice aponta o caminho mínimo de leitura e cada feature registra o contexto suficiente para mudanças futuras.

### Arquivos alterados

- `AGENTS.md`: fluxo obrigatório do projeto.
- `docs/sdd/*`: memória SDD e navegação.
- `Tests/TempoTests/Harness/*`: drivers reutilizáveis.
- `Tests/TempoTests/Fixtures/*`: dados determinísticos.
- `Tests/TempoTests/AppModelSleepTests.swift`: refatorado para harness.
- `Tests/TempoTests/VideoExporterTests.swift`: refatorado para fixtures/harness.
- `Scripts/test.sh`: entrada única de validação.
- `Scripts/package-source.sh`: pacote de código sem caches de build.

### Harnesses e fixtures

- `AppModelHarness`
- `PixelBufferHarness`
- `TemporaryDirectoryFixture`
- `VideoFrameFixture`

### Verificação

- Comando: `Scripts/test.sh`.
- Resultado: 7 testes executados, 6 aprovados, 1 pulado explicitamente porque o serviço H.264 não está disponível no sandbox, 0 falhas.

### Limitações conhecidas

O teste completo do encoder H.264 é opt-in com `TEMPO_RUN_ENCODER_TESTS=1 Scripts/test.sh`; permissões TCC continuam exigindo execução interativa do app no macOS.
