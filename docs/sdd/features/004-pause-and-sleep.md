# TEMPO-F004 — Pausa, repouso e retomada confirmada

- Status: `implemented`
- Versão: `1.1.0`
- Atualizado em: `2026-08-25`

## Contexto

Quando o Mac dormia, uma falha de captura podia encerrar e apagar a sessão. O usuário precisa pausar manualmente e ter proteção automática durante repouso ou bloqueio.

## Requirements

- `TEMPO-F004-R01` — WHEN the user pauses manually THEN Tempo SHALL stop new captures and preserve existing frames.
- `TEMPO-F004-R02` — WHEN screens sleep, the Mac sleeps, or the session becomes inactive THEN Tempo SHALL pause automatically.
- `TEMPO-F004-R03` — WHEN the system wakes after an automatic pause THEN Tempo SHALL notify the user and require confirmation before resuming.
- `TEMPO-F004-R04` — WHEN capture is interrupted unexpectedly THEN Tempo SHALL preserve frames and offer resume or export instead of discarding the session.
- `TEMPO-F004-R05` — IF the pause was manual THEN a wake event SHALL NOT ask to resume.

## Design

`AppModel` observa o `notificationCenter` do `NSWorkspace`. Pausar cancela somente o task de captura; o ator `CaptureSession` e seus arquivos permanecem vivos. `NotificationCoordinator` oferece ações Continuar/Manter pausado e o alerta SwiftUI funciona como fallback.

### Decisões

- `TEMPO-F004-D01` — Retomada automática silenciosa foi rejeitada por privacidade.
- `TEMPO-F004-D02` — Impedir repouso foi rejeitado como padrão por consumo de bateria.
- `TEMPO-F004-D03` — Qualquer erro inesperado pausa; nenhum erro do loop descarta quadros automaticamente.

## Tasks

- [x] Adicionar estado e controles de pausa. _Requirements: R01_
- [x] Observar repouso e sessão. _Requirements: R02_
- [x] Enviar notificação e alerta. _Requirements: R03, R05_
- [x] Preservar sessão em erro. _Requirements: R04_
- [x] Criar testes de eventos. _Requirements: R02, R03, R05_

## Implementation record

### O que foi implementado

Pausa/continuação manual, pausa automática por repouso ou bloqueio, relógio que exclui o tempo pausado, notificação acionável e recuperação conservadora de interrupções.

### Como foi implementado

O task de captura é cancelado e aguardado sem chamar `discard`. Na retomada, o mesmo `CaptureSession` reinicia o loop. Eventos de despertar apenas exibem confirmação quando `PauseReason.isAutomatic` é verdadeiro.

### Arquivos alterados

- `Sources/Tempo/AppModel.swift`
- `Sources/Tempo/Models.swift`
- `Sources/Tempo/NotificationCoordinator.swift`
- `Sources/Tempo/ContentView.swift`
- `Sources/Tempo/Theme.swift`

### Harnesses e fixtures

- `AppModelHarness` publica eventos determinísticos do `NSWorkspace`.

### Verificação

- `testScreenSleepPausesAndWakeRequiresConfirmation`
- `testManualPauseDoesNotAskToResumeAfterWake`
- Suite completa sem falhas.

### Limitações conhecidas

Se notificações forem negadas, a confirmação continua disponível dentro do app.
