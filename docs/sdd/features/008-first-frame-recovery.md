# TEMPO-F008 — Recuperação da primeira captura

- Status: `implemented`
- Versão: `1.1.2`
- Atualizado em: `2026-08-26`

## Contexto

O app exibiu oito segundos de gravação, pausou e depois informou que a gravação terminou antes do primeiro quadro. O relógio era iniciado antes do primeiro JPEG e uma única falha de ScreenCaptureKit encerrava o loop. Assim, uma transição de tela, display virtual ou captura concorrente podia parecer uma gravação válida mesmo sem dados salvos.

## Requirements

**História:** Como usuário, quero que falhas breves de captura sejam recuperadas sem falsa gravação, para obter um vídeo ou um diagnóstico claro sem perder quadros.

- `TEMPO-F008-R01` — WHEN screen capture fails transiently THEN Tempo SHALL retry automatically before pausing the recording.
- `TEMPO-F008-R02` — UNTIL the first frame is stored THEN Tempo SHALL report zero captured duration and zero frames.
- `TEMPO-F008-R03` — WHEN capture succeeds after transient failures THEN Tempo SHALL remain recording and start the recording clock from that successful frame.
- `TEMPO-F008-R04` — WHEN repeated capture failures persist THEN Tempo SHALL pause, preserve existing frames and expose the last capture error.
- `TEMPO-F008-R05` — IF no frame has been stored THEN Tempo SHALL offer cancellation or continuation instead of offering video export.
- `TEMPO-F008-R06` — WHEN Tempo starts while another recent Tempo session exists THEN Tempo SHALL NOT delete that session's temporary frames.

### Casos de borda

- Falha antes do primeiro quadro não deve produzir duração fictícia.
- Falha após quadros válidos não deve apagar nem reiniciar a sessão.
- Cancelamento durante o intervalo de retentativa deve terminar imediatamente.
- Uma captura bem-sucedida entre falhas reinicia a contagem de falhas consecutivas.
- Diretórios recentes de outra instância do Tempo são preservados; somente sessões com mais de 24 horas são consideradas abandonadas.

## Design

### Visão geral

O loop coordenado por `AppModel` fará até cinco tentativas consecutivas com espera progressiva. Um pequeno tracker isolado registra se houve captura entre erros. O relógio passa a iniciar no callback do primeiro quadro real.

### Componentes e interfaces

- `AppModel`: política de retentativa, duração real, último erro e ação de cancelamento.
- `CaptureSessionProtocol`: continua sendo a fronteira para falhas programáveis no harness.
- `AppModelHarness`: recebe uma sequência determinística de falha/sucesso.
- `ContentView`: mostra Cancelar quando não há quadro exportável e detalha a falha.
- `TemporarySessionCleaner`: remove apenas diretórios Tempo realmente antigos.

### Erros e recuperação

- Falhas 1–4: registrar diagnóstico e tentar novamente com backoff.
- Quinta falha consecutiva: pausar com `.captureInterrupted` e manter a sessão.
- Falha com zero quadro: não oferecer criação de vídeo.

### Decisões

- `TEMPO-F008-D01` — Retentativa limitada foi escolhida em vez de pausar no primeiro erro, para tolerar transições de displays sem esconder falhas persistentes.
- `TEMPO-F008-D02` — O relógio mede somente períodos que já produziram ao menos um quadro; preparação e retentativas iniciais ficam fora da duração.
- `TEMPO-F008-D03` — Não afirmar conflito com outros apps sem o erro do sistema; o último erro será preservado para diagnóstico.
- `TEMPO-F008-D04` — Limpeza por idade substitui a exclusão indiscriminada para evitar perda de JPEGs quando duas versões do Tempo estiverem abertas.

### Estratégia de testes

- A sessão falsa falha duas vezes e depois captura, sem acessar ScreenCaptureKit.
- O teste verifica zero duração antes do sucesso, três inícios de loop, um quadro armazenado e estado final `recording`.
- A fixture de diretório cria sessões recente e antiga e verifica que somente a antiga é removida.

## Tasks

- [x] Implementar retentativa limitada e rastreamento de sucesso. _Requirements: TEMPO-F008-R01, TEMPO-F008-R03, TEMPO-F008-R04_
- [x] Iniciar o relógio somente no primeiro quadro real. _Requirements: TEMPO-F008-R02, TEMPO-F008-R03_
- [x] Expor diagnóstico e impedir exportação vazia. _Requirements: TEMPO-F008-R04, TEMPO-F008-R05_
- [x] Estender harness e adicionar regressão determinística. _Requirements: TEMPO-F008-R01, TEMPO-F008-R02, TEMPO-F008-R03_
- [x] Proteger temporários recentes de outra instância. _Requirements: TEMPO-F008-R06_
- [x] Atualizar versão, índice, rastreabilidade e pacotes.

## Implementation record

### O que foi implementado

- Até cinco tentativas consecutivas com backoff de 0,5 s a 4 s.
- Relógio iniciado somente após o primeiro callback de quadro salvo.
- Estado visual de preparação/reconexão e erro real após falha persistente.
- Cancelamento, em vez de exportação, quando existem zero quadros.
- Limpeza de temporários limitada a sessões com mais de 24 horas.
- Versão `1.1.2` (`CFBundleVersion` 6).

### Como foi implementado

`CaptureFailureTracker` diferencia falhas consecutivas de falhas separadas por uma captura válida. `AppModel.startCaptureLoop` tenta novamente e só chama a pausa conservadora no limite. O callback de sucesso inicia `segmentStartedAt`, libera exportação e limpa o diagnóstico. `TemporarySessionCleaner` usa a data de modificação para preservar sessões recentes.

### Arquivos alterados

- `Sources/Tempo/AppModel.swift`: retentativa, relógio real, erro e cancelamento.
- `Sources/Tempo/ContentView.swift`: preparação, reconexão e ações coerentes com os quadros.
- `Sources/Tempo/Models.swift`: mensagem de zero quadros mais acionável.
- `Sources/Tempo/TemporarySessionCleaner.swift`: limpeza segura por idade.
- `Tests/TempoTests/Harness/AppModelHarness.swift`: resultados programáveis de captura.
- `Tests/TempoTests/AppModelCaptureRecoveryTests.swift`: regressões de recuperação.
- `Tests/TempoTests/TemporarySessionCleanerTests.swift`: proteção de sessão recente.
- `Resources/Info.plist`: versão 1.1.2 (6).

### Harnesses e fixtures

- `CaptureSessionHarness`: sequências `.failure`, `.success` e `.successThenFailure`.
- `AppModelHarness`: atraso de teste curto e limite configurável.
- `TemporaryDirectoryFixture`: diretórios recente, antigo e não relacionado.

### Verificação

- `Scripts/test.sh`: 12 testes executados, 11 aprovados, 1 H.264 pulado explicitamente, 0 falhas.
- `testTransientFailuresRecoverBeforePausing`: duas falhas seguidas de sucesso.
- `testPersistentFailuresPauseWithDiagnosticAndNoFakeDuration`: falha persistente sem duração fictícia.
- `testSuccessfulFrameResetsConsecutiveFailureCount`: sucesso reinicia o contador.
- `testCleanupPreservesRecentTempoSessionAndRemovesOnlyStaleSession`: não apaga sessão ativa.

### Limitações conhecidas

- O erro real de ScreenCaptureKit só pode confirmar ou descartar conflito com Codex Computer Use/OpenDisplay durante um teste no Mac. A nova UI preserva e mostra esse erro se todas as tentativas falharem.
