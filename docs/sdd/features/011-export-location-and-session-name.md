# TEMPO-F011 — Pasta de exportação e início da sessão

- Status: `implemented`
- Versão: `1.3.0`
- Atualizado em: `2026-08-27`

## Contexto

O painel de exportação sempre voltava à pasta Filmes e sugeria um nome baseado no momento em que o usuário encerrava a gravação. O usuário quer retornar à última pasta onde um vídeo foi criado e identificar no nome quando a sessão de trabalho começou.

## Requirements

**História:** Como usuário que organiza timelapses por projeto, quero reutilizar a última pasta de exportação e nomear o vídeo pelo início da sessão, para salvar mais rápido e localizar quando o trabalho começou.

- `TEMPO-F011-R01` — WHEN an export succeeds THEN Tempo SHALL persist the directory containing the created video.
- `TEMPO-F011-R02` — WHEN a later save panel opens THEN Tempo SHALL start in the last successfully used export directory.
- `TEMPO-F011-R03` — IF no valid remembered directory exists THEN Tempo SHALL start the save panel in the user's Movies directory.
- `TEMPO-F011-R04` — WHEN a recording session starts THEN Tempo SHALL retain its original start date through pauses and resumes.
- `TEMPO-F011-R05` — WHEN the save panel opens THEN Tempo SHALL suggest a filename containing the original session start date and time rather than the export time.
- `TEMPO-F011-R06` — IF export is cancelled or fails THEN Tempo SHALL NOT replace the remembered successful directory.

### Casos de borda

- Uma pasta lembrada que foi apagada ou virou arquivo é ignorada e o app volta para Filmes.
- Pausar, repousar ou retomar não altera a data de início original.
- Uma nova gravação substitui a data da sessão anterior.
- Se uma sessão legada não tiver data inicial, o instante de exportação é usado como fallback seguro.

## Design

### Visão geral

Uma política pura de destino de exportação concentra nome, validação da pasta e persistência em `UserDefaults`. `AppModel` registra `recordingStartedAt` quando a sessão de captura é criada, consulta a política ao preparar `NSSavePanel` e memoriza o diretório somente depois do sucesso do exportador.

### Componentes e interfaces

- `ExportDestinationPolicy`: gera nome, resolve pasta inicial e persiste uma exportação bem-sucedida.
- `AppModel`: mantém a data original da sessão e integra a política ao painel e ao ciclo de exportação.
- `ExportDestinationHarness`: injeta `UserDefaults` isolado e diretórios de fixture.

### Erros e recuperação

- Caminho persistido inexistente/inválido: usar Filmes sem apagar dados do usuário.
- Exportação cancelada ou falha: manter a preferência anterior.
- Sessão sem data: usar a data de fallback fornecida ao formatador.

### Decisões

- `TEMPO-F011-D01` — Persistir após exportação concluída, e não apenas após escolher o caminho, para que “última pasta” represente um vídeo realmente salvo.
- `TEMPO-F011-D02` — Guardar um caminho local em `UserDefaults`, adequado ao app atual sem sandbox; bookmarks de segurança seriam necessários apenas numa futura distribuição sandboxed.
- `TEMPO-F011-D03` — O início é registrado após a permissão e criação da sessão, antes do primeiro loop de captura, e permanece estável durante pausas.

### Estratégia de testes

- Usar `TemporaryDirectoryFixture` para diretórios válidos, removidos e arquivos inválidos.
- Usar suite isolada de `UserDefaults` no harness para comprovar persistência entre instâncias.
- Validar o nome com datas fixas em `America/Bahia`, provando que o início vence o horário posterior de exportação.

## Tasks

- [x] Criar política de destino e harness determinístico. _Requirements: TEMPO-F011-R01, TEMPO-F011-R02, TEMPO-F011-R03, TEMPO-F011-R05, TEMPO-F011-R06_
- [x] Registrar início original e integrar painel/exportação. _Requirements: TEMPO-F011-R01, TEMPO-F011-R02, TEMPO-F011-R04, TEMPO-F011-R05, TEMPO-F011-R06_
- [x] Adicionar regressões de persistência, fallback e nome. _Requirements: TEMPO-F011-R01, TEMPO-F011-R02, TEMPO-F011-R03, TEMPO-F011-R04, TEMPO-F011-R05, TEMPO-F011-R06_
- [x] Atualizar versão, índice, rastreabilidade e pacotes.

## Implementation record

### O que foi implementado

- O painel abre na pasta da última exportação concluída; no primeiro uso ou se a pasta não existe, abre em Filmes.
- O nome sugerido usa a data e hora originais do início da sessão, preservadas em pausas e retomadas.
- Cancelar o painel ou falhar a exportação não troca a pasta lembrada.
- Versão `1.3.0` (`CFBundleVersion` 9).

### Como foi implementado

- `ExportDestinationPolicy` persiste o caminho em `UserDefaults`, valida que ainda é um diretório e formata o nome com locale `pt_BR`.
- `AppModel.beginRecording` registra `recordingStartedAt`; `resumeRecording` não o altera. O painel usa essa data e a pasta resolvida pela política.
- `rememberSuccessfulExport` é chamado somente depois que `VideoExporter.export` conclui sem erro.

### Arquivos alterados

- `Sources/Tempo/ExportDestinationPolicy.swift`: política de pasta, persistência e nome.
- `Sources/Tempo/AppModel.swift`: início original e integração com exportação.
- `Tests/TempoTests/Harness/ExportDestinationHarness.swift`: persistência isolada entre instâncias.
- `Tests/TempoTests/ExportDestinationPolicyTests.swift`: regressões da feature.
- `Tests/TempoTests/Fixtures/TemporaryDirectoryFixture.swift`: criação reutilizável de arquivo inválido.
- `Resources/Info.plist`: versão 1.3.0 (9).
- `docs/sdd/README.md`, `docs/sdd/ARCHITECTURE.md` e `docs/sdd/TRACEABILITY.md`: memória canônica.

### Harnesses e fixtures

- `ExportDestinationHarness` usa uma suite exclusiva de `UserDefaults` e permite reconstruir a política como em um novo lançamento.
- `TemporaryDirectoryFixture` cria pastas válidas, apagadas e arquivos que não podem ser usados como pasta.

### Verificação

- `Scripts/test.sh`: 22 testes executados, 21 aprovados, 1 H.264 pulado explicitamente, 0 falhas.
- `ExportDestinationPolicyTests`: 5 testes para persistência, relançamento, fallback, caminho inválido e horários fixos.
- Build release ARM64, assinatura ad hoc e pacotes de app/fonte validados.

### Limitações conhecidas

- Uma futura distribuição sandboxed deverá substituir o caminho simples por security-scoped bookmark; o app atual não usa App Sandbox.
