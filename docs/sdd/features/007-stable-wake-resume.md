# TEMPO-F007 — Retomada estável após repouso

- Status: `implemented`
- Versão: `1.1.1`
- Atualizado em: `2026-08-26`

## Contexto

Uma sessão parou em 224 quadros. Ao selecionar Continuar depois do repouso, a gravação voltava imediatamente ao estado pausado. O fluxo existente guardava apenas o primeiro motivo de pausa e oferecia retomada no primeiro evento de despertar, mesmo quando telas, sistema ou sessão ainda tinham interrupções pendentes.

## Requirements

**História:** Como usuário com uma gravação longa, quero continuar após o Mac despertar sem entrar novamente em pausa, para preservar e concluir todo o timelapse.

- `TEMPO-F007-R01` — WHEN multiple system interruptions pause a recording THEN Tempo SHALL remain paused until every corresponding recovery event has occurred.
- `TEMPO-F007-R02` — IF a resume is requested while any system interruption remains active THEN Tempo SHALL keep the session paused and preserve all captured frames.
- `TEMPO-F007-R03` — WHEN all system interruptions have recovered and the user confirms continuation THEN Tempo SHALL start one capture loop and remain recording.
- `TEMPO-F007-R04` — WHEN the final recovery event occurs after an automatic pause THEN Tempo SHALL offer continuation once.

### Casos de borda

- Eventos de repouso podem chegar em ordens diferentes e enquanto o app já está pausado.
- Um evento de despertar parcial não autoriza a retomada.
- Pausa manual continua sem notificação automática de retomada.

## Design

### Visão geral

`AppModel` manterá um conjunto de interrupções ativas para telas, sistema e sessão. Eventos de pausa sempre atualizam esse conjunto, mesmo quando o estado já é `paused`. Cada evento de retorno remove apenas sua interrupção correspondente; a confirmação só aparece quando o conjunto fica vazio.

### Componentes e interfaces

- `AppModel`: rastrear interrupções, proteger `resumeRecording` e expor se a retomada está disponível.
- `CaptureSessionProtocol`: fronteira interna mínima para permitir uma sessão determinística no harness.
- `AppModelHarness`: publicar os pares completos de eventos e dirigir a retomada.
- `ContentView`: impedir a ação Continuar enquanto o sistema ainda não estiver disponível.

### Erros e recuperação

- Retomada antecipada: permanece pausada, sem descartar JPEGs e sem iniciar outro loop.
- Captura interrompida sem evento de repouso: mantém o fluxo conservador existente de Continuar ou exportar.

### Decisões

- `TEMPO-F007-D01` — Rastrear bloqueadores independentes foi escolhido em vez de atraso fixo, porque representa o estado real e não depende da velocidade de despertar do Mac.
- `TEMPO-F007-D02` — O primeiro evento de despertar não libera a captura; somente o último bloqueador removido libera a confirmação.

### Estratégia de testes

- O harness simula três interrupções, retorno parcial, tentativa antecipada e retorno completo.
- Uma sessão falsa conta inícios do loop sem acessar ScreenCaptureKit nem exigir permissão.

## Tasks

- [x] Rastrear interrupções independentes e proteger a retomada. _Requirements: TEMPO-F007-R01, TEMPO-F007-R02_
- [x] Liberar a confirmação apenas após recuperação completa. _Requirements: TEMPO-F007-R04_
- [x] Estender o harness com sessão de captura determinística e eventos de retorno. _Requirements: TEMPO-F007-R02, TEMPO-F007-R03_
- [x] Adicionar teste de regressão da sequência completa. _Requirements: TEMPO-F007-R01, TEMPO-F007-R02, TEMPO-F007-R03, TEMPO-F007-R04_
- [x] Atualizar versão, índice, rastreabilidade e pacotes.

## Implementation record

### O que foi implementado

- Rastreamento independente de tela adormecida, sistema em repouso e sessão inativa.
- Bloqueio de Continuar enquanto qualquer interrupção ainda está ativa.
- Confirmação e notificação somente depois do último evento de recuperação.
- Versão do app atualizada para `1.1.1` (`CFBundleVersion` 5).

### Como foi implementado

`AppModel` mantém um conjunto de bloqueadores. Eventos de repouso entram no conjunto mesmo quando a gravação já está pausada; seus pares de retorno removem somente o bloqueador correspondente. `resumeRecording` exige conjunto vazio. Uma interface interna de sessão permite que o harness conte reinícios sem executar ScreenCaptureKit.

### Arquivos alterados

- `Sources/Tempo/AppModel.swift`: máquina de estados de interrupção e proteção da retomada.
- `Sources/Tempo/CaptureSession.swift`: interface testável da sessão.
- `Sources/Tempo/ContentView.swift`: botão Continuar respeita disponibilidade.
- `Tests/TempoTests/Harness/AppModelHarness.swift`: eventos completos e sessão falsa.
- `Tests/TempoTests/AppModelSleepTests.swift`: regressão com 224 quadros.
- `Resources/Info.plist`: versão 1.1.1 (5).
- `docs/sdd/README.md`, `ARCHITECTURE.md` e `TRACEABILITY.md`: memória e rastreabilidade.

### Harnesses e fixtures

- `AppModelHarness`: ganhou eventos `systemDidWake`, `sessionBecomesActive`, ação de retomada e leitura da contagem de loops.
- `CaptureSessionHarness`: sessão determinística que não requer permissão de gravação de tela.

### Verificação

- `Scripts/test.sh`: 8 testes executados, 7 aprovados, 1 H.264 pulado explicitamente, 0 falhas.
- `testResumeWaitsForEverySystemInterruptionToRecover`: valida 224 quadros preservados, zero início antecipado e exatamente um início após recuperação completa.

### Limitações conhecidas

- A ordem real das notificações de repouso varia pelo macOS; o teste cobre ordem parcial e múltiplos bloqueadores, mas o repouso físico ainda requer validação interativa.
