# Apresentação automática de páginas do Power BI

## Estrutura

- `index.html`: visualizador em tela cheia.
- `slides.json`: ordem e tempo de exibição.
- `slides/`: imagens exportadas do relatório.

## Como usar

1. Exporte cada página do relatório como PNG ou JPG.
2. Renomeie os arquivos, por exemplo:
   - pagina-01.png
   - pagina-02.png
   - pagina-03.png
3. Coloque as imagens dentro da pasta `slides`.
4. Ajuste o arquivo `slides.json`.
5. Inicie um servidor local nesta pasta.

No Windows, com Python instalado:

    python -m http.server 8000

Depois abra:

    http://localhost:8000

## Controles

- Clique na tela para solicitar tela cheia.
- Tecla F: tela cheia.
- Seta direita ou Espaço: próximo slide.
- Seta esquerda: slide anterior.
- Esc: sair da tela cheia.

## Tempo por página

No `slides.json`, o campo `tempo` é informado em segundos:

    {
      "arquivo": "pagina-01.png",
      "tempo": 30
    }

## Atualização dos arquivos

O HTML relê o `slides.json` a cada 60 segundos e adiciona um parâmetro
anticache às imagens. Assim, você pode substituir uma imagem mantendo o
mesmo nome sem precisar alterar o HTML.
