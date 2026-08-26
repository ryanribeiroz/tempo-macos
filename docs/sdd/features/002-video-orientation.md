# TEMPO-F002 — Preservação da orientação do vídeo

- Status: `implemented`
- Versão: `1.0.1`
- Atualizado em: `2026-08-25`

## Contexto

O primeiro exportador aplicava uma transformação vertical desnecessária e o MP4 era produzido de cabeça para baixo.

## Requirements

- `TEMPO-F002-R01` — WHEN a captured frame is written to a video pixel buffer THEN Tempo SHALL preserve its top and bottom rows.
- `TEMPO-F002-R02` — WHEN the video is exported THEN Tempo SHALL preserve the visual orientation of every source JPEG.

## Design

Core Graphics e o CVPixelBuffer BGRA já concordam sobre a ordem das linhas nesse caminho. A transformação adicional foi removida.

### Decisões

- `TEMPO-F002-D01` — Validar orientação por cores assimétricas em memória, sem depender do encoder ou de inspeção humana.

## Tasks

- [x] Reproduzir a inversão com fixture assimétrica. _Requirements: R01_
- [x] Remover a transformação vertical. _Requirements: R01, R02_
- [x] Adicionar teste de regressão. _Requirements: R01_

## Implementation record

### O que foi implementado

Remoção do `translate/scale` vertical e teste que usa topo vermelho e base azul.

### Como foi implementado

`VideoExporter.draw` desenha o `CGImage` diretamente no contexto associado ao pixel buffer. O teste lê os bytes da primeira e última linhas.

### Arquivos alterados

- `Sources/Tempo/VideoExporter.swift`
- `Tests/TempoTests/VideoExporterTests.swift`

### Harnesses e fixtures

- `VideoFrameFixture.topRedBottomBlueImage`
- `PixelBufferHarness`

### Verificação

- `testPixelBufferPreservesVerticalOrientation` falhava antes e passa com a correção.

### Limitações conhecidas

Nenhuma conhecida.
