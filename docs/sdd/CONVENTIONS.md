# Convenções SDD

## Identificadores

- Feature: `TEMPO-FNNN`, por exemplo `TEMPO-F004`.
- Requisito: `TEMPO-FNNN-RNN`, por exemplo `TEMPO-F004-R03`.
- Decisão: `TEMPO-FNNN-DNN`.
- Teste: nome Swift descritivo e requisito correspondente na rastreabilidade.

## Estados de feature

- `proposed`: requisitos em elaboração.
- `designed`: requisitos e design completos.
- `in-progress`: implementação iniciada.
- `implemented`: código, testes e registro final completos.
- `superseded`: substituída, com link para a sucessora.

## Requisitos

Use EARS e comportamento observável:

```text
WHEN [evento] THEN [sistema] SHALL [resposta testável].
IF [condição] THEN [sistema] SHALL [resposta testável].
```

Requisitos não devem conter detalhes de classe, framework ou algoritmo.

## Design

Registre somente decisões que economizam investigação futura:

- responsabilidades e fronteiras;
- estado e transições;
- erros e recuperação;
- alternativas consideradas;
- estratégia de testes.

## Implementation record

Depois do código, preencha obrigatoriamente:

- o que foi implementado;
- como foi implementado;
- arquivos alterados;
- harnesses e fixtures usados;
- testes executados e resultado;
- limitações conhecidas;
- versão do app.

## Harness e fixtures

- **Harness** dirige um componente ou evento e oferece uma API de teste no vocabulário do produto.
- **Fixture** cria dados determinísticos e reutilizáveis.
- Testes devem descrever comportamento; detalhes repetitivos ficam no suporte.
- Um novo helper só entra no harness/fixture se for reutilizável ou remover ruído relevante.

## Commits e versões

O projeto não depende de commits para rastreabilidade. O MD da feature e `TRACEABILITY.md` são obrigatórios mesmo em workspaces sem Git. Mudanças entregues ao usuário incrementam `CFBundleShortVersionString` e `CFBundleVersion`.
