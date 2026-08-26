# Especificação do Tempo

Documentação navegável por feature, decisões e rastreabilidade: `docs/sdd/README.md`.

## Requisitos

**História:** Como usuário de um Mac com mais de uma tela, quero registrar meu período de trabalho como timelapse para rever a sessão inteira em um vídeo curto.

1. QUANDO a gravação começa ENTÃO o app DEVE capturar todas as telas ativas sem áudio.
2. QUANDO duas ou mais telas estão conectadas ENTÃO o app DEVE compô-las respeitando posição e proporção do arranjo do macOS.
3. QUANDO a sessão cresce ENTÃO o app DEVE reduzir uniformemente a amostragem para manter no máximo 1.080 quadros temporários.
4. QUANDO o vídeo é exportado ENTÃO o app DEVE produzir MP4 H.264 com duração máxima de 36 segundos.
5. QUANDO o usuário nega gravação de tela ENTÃO o app DEVE indicar o caminho para habilitar a permissão.
6. QUANDO a exportação termina ou é cancelada ENTÃO o app DEVE remover os quadros temporários.
7. ENQUANTO grava ou exporta ENTÃO o app DEVE mostrar estado, tempo e progresso sem bloquear o restante do sistema.
8. QUANDO o usuário pausa manualmente ENTÃO o app DEVE interromper novas capturas sem apagar os quadros existentes.
9. QUANDO as telas dormem, o Mac entra em repouso ou a sessão fica inativa ENTÃO o app DEVE pausar automaticamente antes que uma falha de captura descarte a sessão.
10. QUANDO as telas ou a sessão voltam E a pausa foi automática ENTÃO o app DEVE manter a gravação pausada, enviar uma notificação e perguntar se o usuário quer continuar.
11. QUANDO a pausa foi manual ENTÃO o app NÃO DEVE retomar nem perguntar automaticamente após um evento de repouso.
12. QUANDO o usuário encerra uma gravação pausada ENTÃO o app DEVE exportar normalmente todos os quadros preservados.
13. QUANDO a captura falha inesperadamente ENTÃO o app DEVE preservar a sessão e oferecer continuar ou exportar, nunca apagar automaticamente os quadros já gravados.

## Design

### Arquitetura

- `AppModel`: estado da interface e coordenação do fluxo.
- `CaptureSession`: ator responsável por snapshots, composição e amostragem adaptativa.
- `FrameSampler`: política pura e testável de compactação temporal.
- `VideoExporter`: codificação MP4 com AVFoundation.
- `NotificationCoordinator`: autorização e ações da notificação local de retomada.
- `ContentView`: interface SwiftUI de uma única janela.

### Decisões

- **Capturas espaçadas em vez de stream contínuo:** reduz CPU, memória e escrita em disco para uso em um Mac de 8 GB.
- **ScreenCaptureKit:** API moderna do macOS, com consentimento explícito do usuário.
- **Amostragem adaptativa:** ao ultrapassar 1.080 quadros, preserva um quadro de cada par e dobra o intervalo futuro. A sessão inteira permanece representada de forma uniforme.
- **Canvas limitado:** 1920×1080 no modo Leve ou 2560×1440 no modo Nítido, sempre sem corte.
- **36 segundos a 30 fps:** 1.080 quadros é um limite simples, previsível e dentro do pedido de 30–40 segundos.
- **Pausa conservadora:** eventos de repouso e bloqueio cancelam apenas o laço de captura; a sessão e os JPEGs temporários continuam intactos.
- **Retomada confirmada:** acordar o Mac nunca reinicia a captura silenciosamente. A pessoa decide pela notificação ou pelo alerta no app.
- **Alternativa não adotada:** impedir o repouso manteria a captura contínua, porém elevaria consumo de bateria e tempo de tela ligada no MacBook Air.

## Tarefas

- [x] Modelar telas, qualidade e amostragem.
- [x] Implementar captura e composição multitelas.
- [x] Implementar exportação H.264.
- [x] Implementar interface e permissões.
- [x] Compilar, executar testes e validar o bundle final.
- [x] Implementar pausa manual e retomada preservando a sessão.
- [x] Observar repouso das telas, do sistema e bloqueio de sessão.
- [x] Adicionar notificação e confirmação de retomada.
- [x] Testar e empacotar a versão com proteção contra repouso.
