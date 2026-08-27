# TEMPO-F010 — Tempo decorrido na barra superior

- Status: `implemented`
- Versão: `1.2.1`
- Atualizado em: `2026-08-26`

## Contexto

A barra superior mostrava somente a quantidade de quadros. O usuário pediu que ela passe a informar o tempo decorrido da gravação, preservando a contagem como detalhe do menu.

## Requirements

**História:** Como usuário em uma gravação longa, quero ver o tempo decorrido ao abrir o menu da barra superior, para acompanhar a duração sem voltar à janela principal.

- `TEMPO-F010-R01` — WHEN a recording is active THEN Tempo SHALL show its captured duration in `HH:MM:SS` in the menu-bar status.
- `TEMPO-F010-R02` — WHEN the menu remains open during a recording THEN Tempo SHALL refresh the displayed duration once per second.
- `TEMPO-F010-R03` — WHEN a recording is active or paused THEN Tempo SHALL show the saved frame count separately in the menu.
- `TEMPO-F010-R04` — IF the recording is paused THEN Tempo SHALL show the accumulated captured duration without advancing it.

### Casos de borda

- Antes do primeiro quadro, o tempo permanece `00:00:00`.
- Valores negativos ou fracionários nunca aparecem como tempo negativo; o formato trunca para segundos completos.

## Design

### Visão geral

`AppChromePolicy` recebe a duração e formata o status de forma pura e testável. `MenuBarControlView` usa `TimelineView` periódico somente para recalcular o texto enquanto o menu estiver aberto; `AppModel` continua sendo a única fonte do relógio. A contagem de quadros vai para uma segunda linha discreta.

### Componentes e interfaces

- `AppChromePolicy.presentation`: passa a receber `recordingDuration` e exibe estado + relógio.
- `AppChromePolicy.formattedDuration`: formata intervalo seguro em `HH:MM:SS`.
- `MenuBarControlView`: atualiza o status por segundo e exibe quadros salvos sob ele.
- `AppChromeHarness`: expõe a duração para testes sem interface gráfica.

### Erros e recuperação

- Duração negativa é limitada a zero antes da formatação.
- Em pausa, `AppModel.recordingDuration` retorna apenas os segmentos concluídos, portanto o menu não avança.

### Decisões

- `TEMPO-F010-D01` — O relógio aparece no status do menu, em vez do rótulo do ícone, pois o `MenuBarExtra` usa somente um símbolo compacto e evita ocupar espaço persistente na barra do macOS.
- `TEMPO-F010-D02` — `TimelineView` não publica estado novo no modelo; ele apenas atualiza a leitura do relógio, mantendo custo leve.

### Estratégia de testes

- `AppChromeHarness` valida os textos de gravação/pausa e a formatação de duração, inclusive bordas negativas.
- O build valida a composição do menu; atualização visual contínua exige checagem interativa no macOS.

## Tasks

- [x] Atualizar a política e o harness para duração formatada. _Requirements: TEMPO-F010-R01, TEMPO-F010-R04_
- [x] Atualizar o menu com relógio periódico e contagem separada. _Requirements: TEMPO-F010-R02, TEMPO-F010-R03_
- [x] Executar testes, atualizar pacotes e concluir rastreabilidade. _Requirements: TEMPO-F010-R01, TEMPO-F010-R02, TEMPO-F010-R03, TEMPO-F010-R04_

## Implementation record

### O que foi implementado

- O status do menu agora exibe “Gravando • HH:MM:SS”; quando pausado, exibe “Pausada • HH:MM:SS”.
- A quantidade de quadros foi preservada em uma segunda linha como “N quadros salvos”.
- A versão foi atualizada para 1.2.1 (build 8).

### Como foi implementado

- AppChromePolicy formata a duração de modo puro e limita valores inválidos a zero.
- MenuBarControlView usa TimelineView de um segundo enquanto o menu está aberto e consulta AppModel.recordingDuration; o modelo continua controlando segmentos ativos e pausados.

### Arquivos alterados

- Sources/Tempo/AppChromePolicy.swift: status com relógio e formatador seguro.
- Sources/Tempo/MenuBarControlView.swift: atualização periódica e métrica de quadros.
- Sources/Tempo/TempoApp.swift: interface atualizada da política.
- Tests/TempoTests/Harness/AppChromeHarness.swift: injeta duração na política.
- Tests/TempoTests/AppChromeTests.swift: regressões de textos e formato.
- Resources/Info.plist: versão 1.2.1 (8).
- docs/sdd/README.md e docs/sdd/TRACEABILITY.md: índice e rastreabilidade.

### Harnesses e fixtures

- AppChromeHarness foi estendido; nenhuma fixture é necessária, pois duração é um valor determinístico.

### Verificação

- Scripts/test.sh: 17 testes executados, 16 aprovados, 1 H.264 pulado explicitamente, 0 falhas.
- Build release ARM64, assinatura ad hoc e git diff --check concluídos.
- Scripts/package-app.sh e Scripts/package-source.sh atualizaram os pacotes distribuíveis.

### Limitações conhecidas

- A atualização visual por segundo do menu aberto requer confirmação interativa no macOS; a lógica de atualização e a formatação estão cobertas por teste e build.
