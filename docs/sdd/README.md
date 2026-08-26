# Índice SDD do Tempo

Este é o primeiro arquivo a ler. Ele contém contexto suficiente para localizar a feature correta sem percorrer todo o código.

## Visão rápida

Tempo é um app SwiftUI para macOS 14+ que captura todas as telas com ScreenCaptureKit, mantém uma amostragem adaptativa em JPEG e exporta MP4 H.264 de até 36 segundos.

## Mapa de leitura

| Área | Leia primeiro | Código principal |
|---|---|---|
| Captura multitelas e limite de 36 s | [001-core-timelapse.md](features/001-core-timelapse.md) | `CaptureSession.swift`, `FrameSampler.swift` |
| Vídeo invertido/orientação | [002-video-orientation.md](features/002-video-orientation.md) | `VideoExporter.swift` |
| Permissão repetida de gravação | [003-screen-permission.md](features/003-screen-permission.md) | `AppModel.swift`, `package-app.sh` |
| Pausa, repouso e retomada | [004-pause-and-sleep.md](features/004-pause-and-sleep.md) | `AppModel.swift`, `NotificationCoordinator.swift`, `ContentView.swift` |
| Metodologia, harness e fixtures | [005-sdd-test-infrastructure.md](features/005-sdd-test-infrastructure.md) | `Tests/TempoTests/Harness`, `Tests/TempoTests/Fixtures` |
| Publicação e convenções Git | [006-github-publication.md](features/006-github-publication.md) | `.gitignore`, `.gitattributes`, `Scripts/package-source.sh` |

## Referências transversais

- [Arquitetura](ARCHITECTURE.md): responsabilidades e fluxos entre componentes.
- [Rastreabilidade](TRACEABILITY.md): requisito → implementação → teste.
- [Convenções](CONVENTIONS.md): IDs, estados, documentação e testes.
- [Template de feature](templates/FEATURE.md): estrutura obrigatória para novas mudanças.
- `../../SPEC.md`: especificação consolidada do produto.

## Regra de economia de contexto

Não leia todos os documentos nem todos os fontes por padrão. Use a tabela acima, abra a feature relevante e siga apenas os caminhos listados em **Arquivos alterados** e **Testes**.
