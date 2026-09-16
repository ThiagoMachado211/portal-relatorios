(() => {
  function initCustomerServiceCharts() {
    const charts = document.querySelectorAll(
      "[data-customer-service-chart]"
    );

    charts.forEach((container) => {
      if (container.dataset.initialized === "true") return;

      let labels;
      let values;

      try {
        labels = JSON.parse(container.dataset.labels || "[]");
        values = JSON.parse(container.dataset.values || "[]");
      } catch (error) {
        console.error(
          "Erro ao interpretar os dados do gráfico de Atendimento ao Cliente:",
          error
        );
        return;
      }

      const format = container.dataset.format || "count";

      if (!labels.length) {
        container.innerHTML =
          '<div class="customer-service-chart-empty">' +
          "Não há dados disponíveis para este indicador." +
          "</div>";

        container.dataset.initialized = "true";
        return;
      }

      drawChart(container, labels, values, format);

      container.dataset.initialized = "true";
    });
  }

  function drawChart(container, labels, values, format) {
    container.innerHTML = "";

    const width = Math.max(container.clientWidth || 900, 600);
    const height = 360;

    const margin = {
      top: 45,
      right: 35,
      bottom: 55,
      left: 85
    };

    const chartWidth = width - margin.left - margin.right;
    const chartHeight = height - margin.top - margin.bottom;

    const numericValues = values.filter(
      (value) => value !== null && value !== undefined
    );

    if (!numericValues.length) {
      container.innerHTML =
        '<div class="customer-service-chart-empty">' +
        "Não há dados disponíveis para este indicador." +
        "</div>";
      return;
    }

    let minValue = Math.min(...numericValues);
    let maxValue = Math.max(...numericValues);

    if (minValue === maxValue) {
      const adjustment =
        maxValue === 0
          ? 1
          : Math.abs(maxValue) * 0.1;

      minValue -= adjustment;
      maxValue += adjustment;
    } else {
      const range = maxValue - minValue;
      const padding = range * 0.12;

      minValue = Math.max(0, minValue - padding);
      maxValue += padding;
    }

    const svg = createSvgElement("svg");

    svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", height);
    svg.setAttribute(
      "aria-label",
      "Gráfico de evolução mensal"
    );
    svg.setAttribute("role", "img");

    container.appendChild(svg);

    const gridLines = 5;

    for (let index = 0; index <= gridLines; index++) {
      const ratio = index / gridLines;

      const y =
        margin.top +
        chartHeight -
        ratio * chartHeight;

      const value =
        minValue +
        ratio * (maxValue - minValue);

      const line = createSvgElement("line");

      line.setAttribute("x1", margin.left);
      line.setAttribute("x2", width - margin.right);
      line.setAttribute("y1", y);
      line.setAttribute("y2", y);
      line.setAttribute(
        "class",
        "customer-service-chart__grid"
      );

      svg.appendChild(line);

      const label = createSvgElement("text");

      label.setAttribute("x", margin.left - 14);
      label.setAttribute("y", y + 4);
      label.setAttribute("text-anchor", "end");
      label.setAttribute(
        "class",
        "customer-service-chart__axis-label"
      );

      label.textContent = formatAxisValue(
        value,
        format
      );

      svg.appendChild(label);
    }

    const xPositions = labels.map((_, index) => {
      if (labels.length === 1) {
        return margin.left + chartWidth / 2;
      }

      return (
        margin.left +
        (index / (labels.length - 1)) *
          chartWidth
      );
    });

    labels.forEach((labelText, index) => {
      const text = createSvgElement("text");

      text.setAttribute("x", xPositions[index]);
      text.setAttribute(
        "y",
        height - margin.bottom + 30
      );
      text.setAttribute("text-anchor", "middle");
      text.setAttribute(
        "class",
        "customer-service-chart__axis-label"
      );

      text.textContent = labelText;

      svg.appendChild(text);
    });

    const points = values.map((value, index) => {
      if (value === null || value === undefined) {
        return null;
      }

      const normalized =
        (value - minValue) /
        (maxValue - minValue);

      return {
        x: xPositions[index],
        y:
          margin.top +
          chartHeight -
          normalized * chartHeight,
        value: value,
        index: index
      };
    });

    drawLineSegments(svg, points);

    points.forEach((point) => {
      if (!point) return;

      drawPoint(
        svg,
        point,
        format
      );
    });
  }

  function drawLineSegments(svg, points) {
    let currentSegment = [];

    function flushSegment() {
      if (currentSegment.length < 2) {
        currentSegment = [];
        return;
      }

      const polyline = createSvgElement(
        "polyline"
      );

      const coordinates = currentSegment
        .map((point) => `${point.x},${point.y}`)
        .join(" ");

      polyline.setAttribute(
        "points",
        coordinates
      );

      polyline.setAttribute(
        "class",
        "customer-service-chart__line"
      );

      polyline.setAttribute("fill", "none");

      svg.appendChild(polyline);

      currentSegment = [];
    }

    points.forEach((point) => {
      if (point) {
        currentSegment.push(point);
      } else {
        flushSegment();
      }
    });

    flushSegment();
  }

  function drawPoint(svg, point, format) {
    const circle = createSvgElement("circle");

    circle.setAttribute("cx", point.x);
    circle.setAttribute("cy", point.y);
    circle.setAttribute("r", 5);
    circle.setAttribute(
      "class",
      "customer-service-chart__point"
    );

    svg.appendChild(circle);

    const label = createSvgElement("text");

    label.setAttribute("x", point.x);
    label.setAttribute("y", point.y - 13);
    label.setAttribute("text-anchor", "middle");
    label.setAttribute(
      "class",
      "customer-service-chart__value"
    );

    label.textContent = formatValue(
      point.value,
      format
    );

    svg.appendChild(label);
  }

  function formatAxisValue(value, format) {
    if (format === "duration") {
      return formatDuration(
        Math.round(value),
        true
      );
    }

    return Math.round(value).toLocaleString(
      "pt-BR"
    );
  }

  function formatValue(value, format) {
    if (format === "duration") {
      return formatDuration(
        Math.round(value),
        false
      );
    }

    return Number(value).toLocaleString(
      "pt-BR"
    );
  }

  function formatDuration(seconds, compact) {
    if (
      seconds === null ||
      seconds === undefined ||
      Number.isNaN(seconds)
    ) {
      return "—";
    }

    const total = Math.max(
      0,
      Math.round(seconds)
    );

    const hours = Math.floor(total / 3600);

    const minutes = Math.floor(
      (total % 3600) / 60
    );

    const secs = total % 60;

    if (compact) {
      if (hours > 0) {
        return `${hours}h${String(minutes).padStart(
          2,
          "0"
        )}`;
      }

      return `${minutes}m`;
    }

    return [
      String(hours).padStart(2, "0"),
      String(minutes).padStart(2, "0"),
      String(secs).padStart(2, "0")
    ].join(":");
  }

  function createSvgElement(name) {
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
      .forEach((container) => {
        container.dataset.initialized = "false";
      });

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

  window.addEventListener("resize", () => {
    clearTimeout(resizeTimer);

    resizeTimer = setTimeout(
      resetCustomerServiceCharts,
      150
    );
  });
})();