# Tempo

Tempo é um gravador de timelapse nativo para macOS. Ele captura todas as telas ativas, preserva o arranjo configurado em Ajustes do Sistema e exporta um único vídeo MP4 de no máximo 36 segundos.

## Requisitos

- Mac com Apple Silicon
- macOS Sonoma 14 ou mais recente
- Permissão de **Gravação da Tela e Áudio do Sistema**

## Como usar

1. Abra `Tempo.app`.
2. Clique em **Iniciar timelapse** e permita a gravação da tela na primeira execução.
3. Trabalhe normalmente. O app captura uma imagem a cada 2 segundos e reduz automaticamente a amostragem em sessões longas.
4. Use **Pausar** e **Continuar** quando quiser interromper temporariamente a captura.
5. Clique em **Parar e criar vídeo**, escolha onde salvar e aguarde a exportação.

## Repouso e bloqueio

- Quando as telas dormem, o Mac entra em repouso ou a sessão é bloqueada, o Tempo pausa automaticamente e preserva todos os quadros.
- Quando as telas voltam, o app envia uma notificação e pergunta se a gravação deve continuar.
- A captura nunca recomeça silenciosamente.
- Se notificações forem negadas, a mesma pergunta continua aparecendo dentro do app.

## Privacidade e desempenho

- Todo o processamento acontece localmente.
- O app não captura áudio.
- No máximo 1.080 imagens JPEG temporárias são mantidas no disco.
- As imagens temporárias são apagadas depois da exportação ou ao cancelar.
- O vídeo usa H.264 com aceleração de hardware quando disponível.

## Desenvolvimento

```sh
swift test
swift build -c release
```

O script `Scripts/package-app.sh` monta e assina localmente o bundle `.app`.

## Metodologia de desenvolvimento

O projeto usa SDD com harnesses, fixtures e documentação por feature. Comece por `docs/sdd/README.md` e execute a validação padrão com:

```sh
Scripts/test.sh
```

Para incluir a integração real com o encoder H.264 em um ambiente sem sandbox:

```sh
TEMPO_RUN_ENCODER_TESTS=1 Scripts/test.sh
```
