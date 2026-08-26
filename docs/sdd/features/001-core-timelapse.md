# TEMPO-F001 — Captura multitelas e timelapse limitado

- Status: `implemented`
- Versão: `1.0.0`
- Atualizado em: `2026-08-25`

## Contexto

Registrar todas as telas de um MacBook Air M1 sem manter um stream pesado nem gerar vídeos longos.

## Requirements

**História:** Como usuário com múltiplas telas, quero rever toda a sessão em um vídeo curto e leve.

- `TEMPO-F001-R01` — WHEN recording starts THEN Tempo SHALL capture every active display in the arrangement configured by macOS.
- `TEMPO-F001-R02` — WHEN stored frames exceed 1,080 THEN Tempo SHALL resample them uniformly and keep at most 1,080.
- `TEMPO-F001-R03` — WHEN export completes THEN Tempo SHALL produce an H.264 MP4 no longer than 36 seconds.
- `TEMPO-F001-R04` — WHEN temporary frames are no longer needed THEN Tempo SHALL remove the session directory.

## Design

- ScreenCaptureKit cria snapshots espaçados, sem áudio.
- `CaptureSession` compõe telas usando os frames globais do macOS.
- `FrameSampler` mantém índices pares e dobra o intervalo após cada compactação.
- `VideoExporter` codifica 30 fps; 1.080 / 30 = 36 segundos.

### Decisões

- `TEMPO-F001-D01` — Snapshots foram escolhidos no lugar de stream contínuo para reduzir CPU, RAM e escrita em disco.
- `TEMPO-F001-D02` — JPEGs ficam no disco; não são acumulados na RAM.

## Tasks

- [x] Implementar composição multitelas. _Requirements: R01_
- [x] Implementar amostragem adaptativa. _Requirements: R02_
- [x] Implementar exportação limitada. _Requirements: R03_
- [x] Limpar temporários. _Requirements: R04_

## Implementation record

### O que foi implementado

Captura de qualquer quantidade de telas, modos 1080p/1440p, amostragem adaptativa e exportação MP4 de até 36 segundos.

### Como foi implementado

`SCShareableContent` lista displays; cada display é capturado e desenhado no canvas conforme sua posição global. O sampler limita a lista de JPEGs e o exportador os apresenta a 30 fps.

### Arquivos alterados

- `Sources/Tempo/CaptureSession.swift`
- `Sources/Tempo/FrameSampler.swift`
- `Sources/Tempo/VideoExporter.swift`
- `Sources/Tempo/Models.swift`

### Harnesses e fixtures

- `VideoFrameFixture`
- `TemporaryDirectoryFixture`
- `PixelBufferHarness`

### Verificação

- `FrameSamplerTests`: limites e compactações repetidas.
- `VideoExporterTests`: contêiner e duração quando o encoder está disponível.

### Limitações conhecidas

Captura real depende da permissão interativa de gravação de tela do macOS.
