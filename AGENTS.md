# Convenções obrigatórias do Tempo

Este projeto usa Spec-Driven Development (SDD). Toda feature, correção de bug ou mudança de comportamento deve deixar uma trilha curta e suficiente para que o próximo trabalho não precise reler o projeto inteiro.

## Ordem de leitura

1. Leia `docs/sdd/README.md`.
2. Leia `docs/sdd/ARCHITECTURE.md` apenas se a mudança atravessar componentes.
3. Leia somente os arquivos de feature apontados pelo índice.
4. Inspecione apenas os arquivos de código e testes listados nessas features.

## Fluxo obrigatório

0. **Grill:** em todo novo bug ou pedido de feature, use a skill global `grill-me` e conclua sua entrevista antes de Requirements.
1. **Requirements:** registre história e critérios EARS (`WHEN/IF ... THEN ... SHALL`).
2. **Design:** registre componentes, interfaces, decisões, erros e estratégia de teste.
3. **Tasks:** liste tarefas rastreáveis aos requisitos antes de implementar.
4. **Implementation:** implemente em fatias testáveis usando os harnesses e fixtures existentes.
5. **Verification:** execute `Scripts/test.sh` e testes adicionais proporcionais ao risco.
6. **Implementation record:** complete o mesmo MD com o que foi implementado, como foi implementado, arquivos, testes e limitações.
7. Atualize `docs/sdd/README.md` e `docs/sdd/TRACEABILITY.md`.

## Documentação por feature

- Caminho: `docs/sdd/features/NNN-nome-curto.md`.
- Use `docs/sdd/templates/FEATURE.md` como base.
- Um bug com mudança de código também recebe um documento de feature.
- O documento deve ser curto, factual e apontar caminhos; não copie código extenso.
- Marque o status como `implemented` somente depois dos testes.

## Testes

- Execute sempre `Scripts/test.sh`.
- Use `Tests/TempoTests/Harness` para dirigir componentes e eventos.
- Use `Tests/TempoTests/Fixtures` para imagens, diretórios e dados repetíveis.
- Não duplique montagem de imagens, buffers, diretórios temporários ou eventos do macOS dentro de testes individuais.
- Todo bug corrigido deve ganhar um teste de regressão que falhe sem a correção.
- Testes que dependem de serviços indisponíveis no sandbox podem ser pulados apenas com motivo explícito; a parte determinística deve continuar coberta.
- O teste real de H.264 é opt-in: `TEMPO_RUN_ENCODER_TESTS=1 Scripts/test.sh` fora do sandbox.

## Definition of done

- Requisitos, design e tarefas registrados.
- Código implementado.
- Harness/fixtures reutilizados ou estendidos.
- Teste de comportamento e regressão presente.
- `Scripts/test.sh` sem falhas.
- Documento da feature concluído.
- Índice e rastreabilidade atualizados.
- App e código-fonte empacotados quando a mudança for destinada ao usuário.

Use `Scripts/package-source.sh` para atualizar o pacote de código-fonte e `Scripts/package-app.sh` para o app.
