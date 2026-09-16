(() => {
  function initCustomerServiceCharts() {
    const charts = document.querySelectorAll(
      "[data-customer-service-chart]"
    );

    charts.forEach((container) => {
      if (container.dataset.initialized === "true") {
        return;
      }

      let labels;
      let values;

      try {
        labels = JSON.parse(
          container.dataset.labels || "[]"
        );

        values = JSON.parse(
          container.dataset.values || "[]"
        );
      } catch (error) {
        console.error(
          "Erro ao interpretar os dados do gráfico:",
          error
        );

        return;
      }

      const format =
        container.dataset.format || "count";

      if (!labels.length) {
        showEmptyState(container);
        return;
      }

      drawChart(
        container,
        labels,
        values,
        format
      );

      container.dataset.initialized = "true";
    });
  }


  function drawChart(
    container,
    labels,
    values,
    format
  ) {
    container.innerHTML = "";

    const width = Math.max(
      container.clientWidth || 900,
      600
    );

    const height = 360;

    /*
     * Como removemos os números do eixo Y,
     * não precisamos reservar uma margem
     * esquerda tão grande.
     */
    const margin = {
      top: 55,
      right: 35,
      bottom: 55,
      left: 35
    };

    const chartWidth =
      width -
      margin.left -
      margin.right;

    const chartHeight =
      height -
      margin.top -
      margin.bottom;


    const numericValues = values.filter(
      (value) =>
        value !== null &&
        value !== undefined &&
        !Number.isNaN(Number(value))
    );


    if (!numericValues.length) {
      showEmptyState(container);
      return;
    }


    let minValue = Math.min(
      ...numericValues
    );

    let maxValue = Math.max(
      ...numericValues
    );


    /*
     * Criamos uma pequena folga acima e
     * abaixo dos valores para que os pontos
     * não encostem nas bordas.
     */
    if (minValue === maxValue) {
      const adjustment =
        maxValue === 0
          ? 1
          : Math.abs(maxValue) * 0.15;

      minValue =
        Math.max(
          0,
          minValue - adjustment
        );

      maxValue += adjustment;
    } else {
      const range =
        maxValue - minValue;

      const padding =
        range * 0.15;

      minValue =
        Math.max(
          0,
          minValue - padding
        );

      maxValue += padding;
    }


    const svg =
      createSvgElement("svg");

    svg.setAttribute(
      "viewBox",
      `0 0 ${width} ${height}`
    );

    svg.setAttribute(
      "width",
      "100%"
    );

    svg.setAttribute(
      "height",
      height
    );

    svg.setAttribute(
      "role",
      "img"
    );

    svg.setAttribute(
      "aria-label",
      "Gráfico de evolução mensal"
    );

    container.appendChild(svg);


    /*
     * Linhas horizontais de referência.
     *
     * Não colocamos mais nenhum número
     * no eixo Y.
     */
    drawHorizontalGrid(
      svg,
      width,
      margin,
      chartHeight
    );


    /*
     * Posições horizontais dos meses.
     */
    const xPositions =
      labels.map((_, index) => {
        if (labels.length === 1) {
          return (
            margin.left +
            chartWidth / 2
          );
        }

        return (
          margin.left +
          (
            index /
            (labels.length - 1)
          ) *
          chartWidth
        );
      });


    /*
     * Meses no eixo X.
     */
    labels.forEach(
      (labelText, index) => {
        const text =
          createSvgElement("text");

        text.setAttribute(
          "x",
          xPositions[index]
        );

        text.setAttribute(
          "y",
          height -
            margin.bottom +
            32
        );

        text.setAttribute(
          "text-anchor",
          "middle"
        );

        text.setAttribute(
          "class",
          "customer-service-chart__axis-label"
        );

        text.textContent =
          labelText;

        svg.appendChild(text);
      }
    );


    /*
     * Converte cada valor em coordenadas
     * X/Y do SVG.
     */
    const points =
      values.map(
        (rawValue, index) => {
          if (
            rawValue === null ||
            rawValue === undefined
          ) {
            return null;
          }

          const value =
            Number(rawValue);

          if (Number.isNaN(value)) {
            return null;
          }

          const normalized =
            (
              value -
              minValue
            ) /
            (
              maxValue -
              minValue
            );

          return {
            x: xPositions[index],

            y:
              margin.top +
              chartHeight -
              normalized *
                chartHeight,

            value: value
          };
        }
      );


    /*
     * PRIMEIRO desenhamos a linha.
     *
     * Assim os pontos e seus valores
     * aparecem por cima dela.
     */
    drawLineSegments(
      svg,
      points
    );


    /*
     * Depois desenhamos os pontos e
     * seus respectivos valores.
     */
    points.forEach((point) => {
      if (!point) {
        return;
      }

      drawPoint(
        svg,
        point,
        format
      );
    });
  }


  function drawHorizontalGrid(
    svg,
    width,
    margin,
    chartHeight
  ) {
    const gridLines = 4;

    for (
      let index = 0;
      index <= gridLines;
      index++
    ) {
      const ratio =
        index / gridLines;

      const y =
        margin.top +
        chartHeight -
        ratio *
          chartHeight;

      const line =
        createSvgElement("line");

      line.setAttribute(
        "x1",
        margin.left
      );

      line.setAttribute(
        "x2",
        width -
          margin.right
      );

      line.setAttribute(
        "y1",
        y
      );

      line.setAttribute(
        "y2",
        y
      );

      line.setAttribute(
        "class",
        "customer-service-chart__grid"
      );

      svg.appendChild(line);
    }
  }


  /*
   * Desenha linhas entre pontos consecutivos.
   *
   * Se existir um mês sem informação
   * (null), a linha é interrompida naquele
   * ponto. Não transformamos ausência em zero.
   */
  function drawLineSegments(
    svg,
    points
  ) {
    let currentSegment = [];


    function flushSegment() {
      if (
        currentSegment.length >= 2
      ) {
        const polyline =
          createSvgElement(
            "polyline"
          );

        const coordinates =
          currentSegment
            .map(
              (point) =>
                `${point.x},${point.y}`
            )
            .join(" ");

        polyline.setAttribute(
          "points",
          coordinates
        );

        polyline.setAttribute(
          "fill",
          "none"
        );

        /*
         * Definimos os atributos essenciais
         * diretamente aqui para garantir que
         * a linha apareça mesmo se alguma regra
         * antiga do CSS estiver sobrescrevendo
         * a classe.
         */
        polyline.setAttribute(
          "stroke",
          "#2563eb"
        );

        polyline.setAttribute(
          "stroke-width",
          "3"
        );

        polyline.setAttribute(
          "stroke-linecap",
          "round"
        );

        polyline.setAttribute(
          "stroke-linejoin",
          "round"
        );

        polyline.setAttribute(
          "class",
          "customer-service-chart__line"
        );

        svg.appendChild(
          polyline
        );
      }

      currentSegment = [];
    }


    points.forEach((point) => {
      if (point) {
        currentSegment.push(
          point
        );
      } else {
        flushSegment();
      }
    });


    flushSegment();
  }


  function drawPoint(
    svg,
    point,
    format
  ) {
    const circle =
      createSvgElement("circle");

    circle.setAttribute(
      "cx",
      point.x
    );

    circle.setAttribute(
      "cy",
      point.y
    );

    circle.setAttribute(
      "r",
      "5"
    );

    circle.setAttribute(
      "fill",
      "#ffffff"
    );

    circle.setAttribute(
      "stroke",
      "#2563eb"
    );

    circle.setAttribute(
      "stroke-width",
      "3"
    );

    circle.setAttribute(
      "class",
      "customer-service-chart__point"
    );

    svg.appendChild(circle);


    /*
     * Valor sobre o ponto.
     */
    const label =
      createSvgElement("text");

    label.setAttribute(
      "x",
      point.x
    );

    label.setAttribute(
      "y",
      point.y - 14
    );

    label.setAttribute(
      "text-anchor",
      "middle"
    );

    label.setAttribute(
      "class",
      "customer-service-chart__value"
    );

    label.textContent =
      formatValue(
        point.value,
        format
      );

    svg.appendChild(label);
  }


  function formatValue(
    value,
    format
  ) {
    if (format === "duration") {
      return formatDuration(
        Math.round(value)
      );
    }

    return Number(
      value
    ).toLocaleString(
      "pt-BR"
    );
  }


  function formatDuration(seconds) {
    if (
      seconds === null ||
      seconds === undefined ||
      Number.isNaN(seconds)
    ) {
      return "—";
    }

    const total =
      Math.max(
        0,
        Math.round(seconds)
      );

    const hours =
      Math.floor(
        total / 3600
      );

    const minutes =
      Math.floor(
        (
          total % 3600
        ) / 60
      );

    const secs =
      total % 60;

    return [
      String(hours).padStart(
        2,
        "0"
      ),

      String(minutes).padStart(
        2,
        "0"
      ),

      String(secs).padStart(
        2,
        "0"
      )
    ].join(":");
  }


  function showEmptyState(
    container
  ) {
    container.innerHTML =
      '<div class="customer-service-chart-empty">' +
      "Não há dados disponíveis para este indicador." +
      "</div>";

    container.dataset.initialized =
      "true";
  }


  function createSvgElement(
    name
  ) {
    return document.createElementNS(
      "http://www.w3.org/2000/svg",
      name
    );
  }


  function resetCustomerServiceCharts() {
    document
      .querySelectorAll(
        "[data-customer-service-chart]"
      )
      .forEach(
        (container) => {
          container.dataset.initialized =
            "false";
        }
      );

    initCustomerServiceCharts();
  }


  document.addEventListener(
    "DOMContentLoaded",
    initCustomerServiceCharts
  );


  document.addEventListener(
    "turbo:load",
    initCustomerServiceCharts
  );


  let resizeTimer;


  window.addEventListener(
    "resize",
    () => {
      clearTimeout(
        resizeTimer
      );

      resizeTimer =
        setTimeout(
          resetCustomerServiceCharts,
          150
        );
    }
  );
})();