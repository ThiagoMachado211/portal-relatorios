# Atendimento ao Cliente — Especificação dos indicadores

## Período inicial
Março/2026 a Setembro/2026.

## Unidade de armazenamento
Uma linha por mês no PostgreSQL. As linhas por atendente existem apenas nos CSVs de origem e são consolidadas durante a importação.

## Indicadores exibidos no relatório

### Contagens — soma dos atendentes
- Respostas → `RESPOSTAS`
- Primeiras Respostas → `PRIMEIRAS RESPOSTAS`
- Tíquetes FCR → `TÍQUETES FCR`
- Tíquetes Fechados → `TÍQUETES FECHADOS`
- Tíquetes Reabertos → `TÍQUETES REABERTOS`

`SAÍDA` também é importado e armazenado, mas não será exibido inicialmente.

### Tempos — médias ponderadas
- Tempo de Primeira Resposta (médio): ponderado por `PRIMEIRAS RESPOSTAS`.
- Tempo de Resposta (médio): ponderado por `RESPOSTAS`.
- Tempo de Resolução (médio): ponderado por `TÍQUETES FECHADOS`.

Fórmula:

`média = soma(tempo_médio_do_atendente × peso_do_atendente) / soma(pesos_válidos)`

Uma linha com duração `-`, vazia ou peso zero não participa do denominador daquela média.

## Durações
As durações são armazenadas como segundos inteiros. O importador reconhece `HH:MM:SS` e durações do Zoho com dias/horas, como `1d 13h`.

## Ausência não é zero
Quando não há observação válida para um tempo médio, o banco recebe `NULL`, não `0`. Isso é essencial para março/2026 em Tempo de Primeira Resposta e Tempo de Resposta.

## Atualização futura
Novos arquivos devem seguir o padrão `Suporte_MmmAA.csv`, por exemplo `Suporte_Out26.csv`. A importação usa `find_or_initialize_by(year:, month:)`, portanto reimportar um mês atualiza o registro correspondente sem criar duplicata.
