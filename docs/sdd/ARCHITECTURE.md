# Arquitetura

## Fluxo principal

```text
ContentView
    ↓ ações/estado
AppModel
    ├── CaptureSession → ScreenCaptureKit → JPEGs temporários
    ├── VideoExporter → AVFoundation → MP4
    ├── ExportDestinationPolicy → UserDefaults
    └── NotificationCoordinator → UserNotifications

TempoApp
    ├── WindowGroup → ContentView
    └── MenuBarExtra → MenuBarControlView
            ↓ mesmas ações/estado
          AppModel
```

## Componentes

| Componente | Responsabilidade | Não deve fazer |
|---|---|---|
| `ContentView` | Renderizar estado e enviar intenções | Capturar, persistir ou codificar |
| `AppModel` | Coordenar ciclo, permissões, pausa e exportação | Implementar composição de pixels |
| `CaptureSession` | Capturar/compor telas e manter amostragem | Controlar UI ou pedir local de arquivo |
| `FrameSampler` | Limitar quadros uniformemente | Acessar disco ou APIs do macOS |
| `VideoExporter` | Converter JPEGs em MP4 H.264 | Decidir ciclo de gravação |
| `ExportDestinationPolicy` | Lembrar pasta válida e nomear pelo início da sessão | Exibir painel ou codificar vídeo |
| `NotificationCoordinator` | Autorizar, enviar e tratar ações locais | Alterar diretamente a sessão |
| `MenuBarControlView` | Expor ações contextuais na barra superior | Duplicar estado de gravação |
| `AppChromePolicy` | Mapear fases para janela, ícone e ações | Acessar AppKit |
| `AppWindowController` | Minimizar e restaurar a janela principal | Decidir ciclo de gravação |

## Estado da gravação

```text
idle → requestingPermission → recording ⇄ paused → exporting → finished
                                  │                     │
                                  └────── failure ──────┘
```

`paused` preserva `CaptureSession` e seus JPEGs. Repouso, bloqueio ou interrupção nunca descartam quadros. `exporting` é o único caminho normal que encerra a sessão.

Eventos de repouso podem se sobrepor. `AppModel` rastreia separadamente telas adormecidas, sistema em repouso e sessão inativa; a retomada só é habilitada depois que todos os bloqueadores recebem seu evento de recuperação.

Falhas de captura recebem até cinco tentativas com backoff. O relógio de um segmento só começa no primeiro quadro realmente salvo. Falha persistente pausa sem descartar a sessão e mantém o último erro para diagnóstico.

## Dados temporários

- Diretório por sessão: `Tempo-<UUID>` no diretório temporário do usuário.
- Limpeza de abandono: somente diretórios `Tempo-*` sem modificação há mais de 24 horas.
- Quadro: JPEG nomeado por sequência crescente.
- Limite: 1.080 quadros; compactação mantém índices pares e dobra o intervalo.
- Saída: MP4 H.264, 30 fps, no máximo 36 segundos.
- Pasta de saída: última exportação bem-sucedida persistida; fallback para Filmes.
- Nome sugerido: data/hora do início original da sessão, não do encerramento.

## Pontos de extensão

- Políticas de repouso pertencem ao `AppModel`.
- Políticas de janela e menu pertencem ao `AppChromePolicy`; efeitos AppKit ficam no `AppWindowController`.
- Preferência visual pertence a `TempoApp` e é compartilhada pelas duas cenas.
- Novos formatos de saída pertencem ao `VideoExporter`.
- Preferências de destino e nomenclatura pertencem ao `ExportDestinationPolicy`.
- Novas estratégias temporais pertencem ao `FrameSampler`.
- Novos dados sintéticos pertencem a `Tests/TempoTests/Fixtures`.
