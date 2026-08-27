# TEMPO-F009 — Controle pela barra superior e aparência

- Status: `implemented`
- Versão: `1.2.0`
- Atualizado em: `2026-08-26`

## Contexto

O Tempo precisa sair do caminho durante uma gravação longa sem perder controles importantes. O usuário confirmou que a janela deve minimizar para o Dock ao começar, o app deve permanecer acessível pela barra superior do macOS e a aparência deve oferecer Sistema, Claro e Escuro com preferência persistente.

## Requirements

**História:** Como usuário que grava uma sessão longa, quero controlar o Tempo pela barra superior e escolher a aparência, para manter a área de trabalho livre e acessar rapidamente a gravação.

- `TEMPO-F009-R01` — WHEN permission succeeds and a new recording starts THEN Tempo SHALL minimize its main window to the Dock.
- `TEMPO-F009-R02` — WHEN Tempo is running THEN macOS SHALL show a menu-bar item reflecting the current recording state.
- `TEMPO-F009-R03` — WHEN the menu-bar item is opened THEN Tempo SHALL offer the valid actions for the current phase, including opening the app, starting, pausing, continuing, stopping and quitting.
- `TEMPO-F009-R04` — WHEN the user asks to open Tempo from the menu bar THEN Tempo SHALL restore and focus the main window.
- `TEMPO-F009-R05` — WHEN the user selects System, Light or Dark appearance THEN Tempo SHALL apply that appearance to the app.
- `TEMPO-F009-R06` — WHEN Tempo is relaunched THEN it SHALL restore the previously selected appearance.
- `TEMPO-F009-R07` — IF a recording contains no frames THEN the menu-bar controls SHALL offer cancellation instead of video export.

### Casos de borda

- Continuar uma gravação pausada não minimiza novamente a janela.
- Iniciar pela barra superior minimiza uma janela existente, mas funciona normalmente se ela estiver fechada.
- Parar pela barra superior restaura o app antes de abrir o painel de salvamento.
- O modo Sistema acompanha claro/escuro do macOS sem sobrescrever a preferência do usuário.

## Design

### Visão geral

`TempoApp` compartilhará um único `AppModel` entre `WindowGroup` e `MenuBarExtra`. Uma política pura decide quando minimizar e como representar cada fase. Um controlador AppKit concentra minimizar/restaurar. `@AppStorage` persiste `AppearanceMode`.

### Direção visual

- **Assunto:** utilitário local de timelapse para quem precisa trabalhar enquanto grava.
- **Paleta clara:** Canvas `#F1F6FA`, Stage `#D9E3EB`, Ink `#17212E`, Muted `#576370`, Main `#2163C7`, External `#388FB0`.
- **Paleta escura:** Canvas `#101722`, Stage `#182433`, Ink `#EDF4FA`, Muted `#9EADBC`, Main `#5B91EC`, External `#4CA7C2`.
- **Sinais:** Record `#E63B38`/`#FF625E` e Pause `#DB7D1A`/`#F2A33A` mantêm significado nas duas aparências.
- **Tipografia:** Avenir Next Condensed para a marca, system rounded para ações e monospaced para métricas.
- **Layout:** manter o painel compacto 620 × 560; o seletor de aparência ocupa apenas um controle no cabeçalho.
- **Assinatura:** o mapa das telas e sua linha de varredura continuam sendo o elemento memorável.

Revisão crítica: o escuro evita preto puro com acento neon genérico; usa azul‑grafite derivado da própria captura multitelas e mantém contraste funcional sem adicionar decoração.

### Componentes e interfaces

- `TempoApp`: cenas compartilhadas e preferência persistida.
- `MenuBarControlView`: ações contextuais e seletor de aparência.
- `AppWindowController`: minimizar, restaurar e focar a janela principal.
- `AppChromePolicy`: transição de minimização e apresentação do ícone/status.
- `ContentView` e `Theme`: seletor e cores adaptativas.

### Erros e recuperação

- Janela indisponível ao restaurar: `openWindow` cria/reabre a cena e o controlador foca na próxima passagem do run loop.
- Ação inválida para a fase: o menu não a apresenta ou a mantém desabilitada.

### Decisões

- `TEMPO-F009-D01` — Minimizar ocorre em `requestingPermission → recording`, não no clique inicial, para manter prompts de permissão visíveis.
- `TEMPO-F009-D02` — O ícone de menu coexiste com o Dock; o Tempo não vira um app exclusivamente de menu.
- `TEMPO-F009-D03` — Uma preferência Sistema/Claro/Escuro foi escolhida em vez de apenas alternância binária.
- `TEMPO-F009-D04` — Ações da barra reutilizam `AppModel`; não existe um segundo estado de gravação.

### Estratégia de testes

- `AppChromeHarness` dirige transições e fases sem abrir janelas reais.
- Testar minimização apenas no início, apresentação de cada fase, ações permitidas e valores persistíveis de aparência.
- A integração visual e o `MenuBarExtra` são validados por build do app; interação real exige macOS gráfico.

## Tasks

- [x] Criar política de janela/menu e harness. _Requirements: TEMPO-F009-R01, TEMPO-F009-R02, TEMPO-F009-R03_
- [x] Criar `MenuBarExtra` com ações contextuais. _Requirements: TEMPO-F009-R02, TEMPO-F009-R03, TEMPO-F009-R04, TEMPO-F009-R07_
- [x] Minimizar no início e restaurar pelo menu. _Requirements: TEMPO-F009-R01, TEMPO-F009-R04_
- [x] Implementar aparência adaptativa e persistente. _Requirements: TEMPO-F009-R05, TEMPO-F009-R06_
- [x] Executar testes, atualizar versão, índice, rastreabilidade e pacotes.

## Implementation record

### O que foi implementado

- Minimização automática para o Dock quando uma nova gravação efetivamente começa.
- Ícone permanente na barra superior com estado e ações contextuais.
- Restauração/foco da janela principal pelo menu superior.
- Modos Sistema, Claro e Escuro persistidos.
- Paleta adaptativa azul‑grafite e seletor discreto no cabeçalho.
- Versão `1.2.0` (`CFBundleVersion` 7).

### Como foi implementado

`TempoApp` mantém um único `AppModel` para as cenas `WindowGroup` e `MenuBarExtra`. `AppChromePolicy` traduz fase em ícone, texto, ações e decisão de minimizar. `AppWindowController` concentra AppKit. `AppearanceMode` fica em `@AppStorage`; as cores dinâmicas respondem à aparência efetiva.

### Arquivos alterados

- `Sources/Tempo/TempoApp.swift`: cenas compartilhadas e persistência.
- `Sources/Tempo/MenuBarControlView.swift`: menu superior e ações.
- `Sources/Tempo/AppWindowController.swift`: minimizar/restaurar.
- `Sources/Tempo/AppChromePolicy.swift`: política testável e aparência.
- `Sources/Tempo/ContentView.swift`: seletor e aplicação do tema.
- `Sources/Tempo/Theme.swift`: cores adaptativas.
- `Tests/TempoTests/Harness/AppChromeHarness.swift`: driver da política.
- `Tests/TempoTests/AppChromeTests.swift`: regressões de janela, menu e aparência.
- `Resources/Info.plist`: versão 1.2.0 (7).

### Harnesses e fixtures

- `AppChromeHarness`: dirige transições, apresentações e ações sem abrir AppKit.
- Nenhuma fixture nova foi necessária; a feature não cria mídia nem dados temporários.

### Verificação

- `Scripts/test.sh`: 16 testes executados, 15 aprovados, 1 H.264 pulado explicitamente, 0 falhas.
- `AppChromeTests`: 4 testes para minimização, estado, ações e persistência.
- Build release ARM64 e assinatura ad hoc válidos.
- Smoke test do app em aparência escura: iniciou sem crash.

### Limitações conhecidas

- Posição visual do item na barra superior e animação real de minimizar exigem validação interativa no macOS do usuário.
