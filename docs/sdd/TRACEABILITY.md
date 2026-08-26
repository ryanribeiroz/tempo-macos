# Rastreabilidade

| Requisito | Comportamento | Implementação | Teste |
|---|---|---|---|
| `TEMPO-F001-R01` | Capturar todas as telas no arranjo do macOS | `CaptureSession.captureComposite` | Validação de build; captura requer permissão interativa |
| `TEMPO-F001-R02` | Limitar a sessão a 1.080 quadros | `FrameSampler.indicesToKeep` | `FrameSamplerTests` |
| `TEMPO-F001-R03` | Exportar no máximo 36 s | `VideoExporter.framesPerSecond` + limite do sampler | `VideoExporterTests.testCreatesPlayableH264Video` |
| `TEMPO-F002-R01` | Manter orientação vertical | `VideoExporter.draw` | `testPixelBufferPreservesVerticalOrientation` |
| `TEMPO-F003-R01` | Não pedir permissão já concedida | `CaptureSession.verifyAccess`, `AppModel.start` | Build; autorização requer teste interativo |
| `TEMPO-F003-R02` | Manter identidade entre builds | `Scripts/package-app.sh` | `codesign -d -r- Tempo.app` |
| `TEMPO-F004-R01` | Pausar e continuar manualmente | `AppModel.pauseManually/resumeRecording` | `AppModelSleepTests.testManualPauseDoesNotAskToResumeAfterWake` |
| `TEMPO-F004-R02` | Pausar ao dormir/bloquear | Observadores `NSWorkspace` no `AppModel` | `testScreenSleepPausesAndWakeRequiresConfirmation` |
| `TEMPO-F004-R03` | Confirmar retomada | `NotificationCoordinator`, alerta em `ContentView` | `testScreenSleepPausesAndWakeRequiresConfirmation` |
| `TEMPO-F004-R04` | Preservar quadros em interrupções | `pauseAfterCaptureInterruption` | Inspeção do estado; sessão não chama `discard` |
| `TEMPO-F005-R01` | Usar harnesses e fixtures | `Tests/TempoTests/Harness`, `Fixtures` | `Scripts/test.sh` |
| `TEMPO-F005-R02` | Documentar cada feature | `docs/sdd/features` + template | Auditoria do índice |
| `TEMPO-F006-R01` | Publicar fontes, testes e documentação | Raiz do repositório `work/Tempo` | Revisão de `git ls-tree` |
| `TEMPO-F006-R02` | Excluir caches e artefatos | `.gitignore`, `package-source.sh` | Revisão de `git status --short` |
| `TEMPO-F006-R03` | `main` rastrear `origin/main` | Configuração Git local | `git status --branch`, `git ls-remote` |
| `TEMPO-F006-R04` | Validar antes do push | `Scripts/test.sh` | Suite padrão sem falhas |
| `TEMPO-F007-R01` | Aguardar todas as recuperações do sistema | Conjunto de interrupções em `AppModel` | `testResumeWaitsForEverySystemInterruptionToRecover` |
| `TEMPO-F007-R02` | Recusar retomada antecipada sem perder quadros | `AppModel.canResume/resumeRecording` | `testResumeWaitsForEverySystemInterruptionToRecover` |
| `TEMPO-F007-R03` | Iniciar um único loop após recuperação completa | `CaptureSessionProtocol`, `startCaptureLoop` | `testResumeWaitsForEverySystemInterruptionToRecover` |
| `TEMPO-F007-R04` | Oferecer retomada após o último retorno | `handleSystemRecovery`, `offerResumeAfterRecovery` | `testResumeWaitsForEverySystemInterruptionToRecover` |
| `TEMPO-F008-R01` | Recuperar falhas transitórias | `AppModel.startCaptureLoop`, `CaptureFailureTracker` | `testTransientFailuresRecoverBeforePausing` |
| `TEMPO-F008-R02` | Não contar duração antes do primeiro quadro | Callback de sucesso em `startCaptureLoop` | `testPersistentFailuresPauseWithDiagnosticAndNoFakeDuration` |
| `TEMPO-F008-R03` | Permanecer gravando após recuperação | `CaptureFailureTracker.markCapture` | `testTransientFailuresRecoverBeforePausing` |
| `TEMPO-F008-R04` | Pausar com diagnóstico após falhas persistentes | `pauseAfterCaptureInterruption(error:)` | `testPersistentFailuresPauseWithDiagnosticAndNoFakeDuration` |
| `TEMPO-F008-R05` | Não oferecer exportação vazia | `AppModel.canExport`, controles de `ContentView` | `testPersistentFailuresPauseWithDiagnosticAndNoFakeDuration` |
| `TEMPO-F008-R06` | Preservar temporários recentes | `TemporarySessionCleaner` | `testCleanupPreservesRecentTempoSessionAndRemovesOnlyStaleSession` |

## Evidências manuais

- Bundle ARM64: `file outputs/Tempo.app/Contents/MacOS/Tempo`.
- Assinatura: `codesign --verify --deep --strict outputs/Tempo.app`.
- Requisito estável: `codesign -d -r- outputs/Tempo.app`.
- Permissões, repouso físico e notificação visual exigem validação no Mac fora do sandbox de testes.
