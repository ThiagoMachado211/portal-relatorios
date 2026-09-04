(() => {
  const SVG_NS = "http://www.w3.org/2000/svg";

  function number(value) {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
  }

  function formatValue(value, suffix = "") {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—";

    return new Intl.NumberFormat("pt-BR", {
      minimumFractionDigits: 1,
      maximumFractionDigits: 1
    }).format(Number(value)) + suffix;
  }

  function svgElement(name, attrs = {}) {
    const element = document.createElementNS(SVG_NS, name);
    Object.entries(attrs).forEach(([key, value]) => element.setAttribute(key, value));
    return element;
  }

  function clear(element) {
    while (element.firstChild) element.removeChild(element.firstChild);
  }

  function parsePayload(element) {
    try {
      return JSON.parse(element.dataset.enemChart || "{}");
    } catch (_error) {
      return {};
    }
  }

  function renderBarChart(container, payload) {
    clear(container);

    const labels = payload.labels || [];
    const values = (payload.values || []).map(number);
    const suffix = payload.suffix || "";
    const validValues = values.filter(v => v !== null);

    if (!labels.length || !validValues.length) {
      container.textContent = "Sem dados para exibir.";
      return;
    }

    const maxValue = number(payload.maximum) || Math.max(...validValues, 1);
    const width = Math.max(container.clientWidth || 760, 520);
    const rowHeight = labels.length > 6 ? 46 : 58;
    const height = Math.max(labels.length * rowHeight + 42, 220);
    const left = labels.some(label => String(label).length > 12) ? Math.min(260, width * 0.32) : 90;
    const right = 92;
    const top = 18;
    const barWidth = Math.max(width - left - right, 120);

    const svg = svgElement("svg", {
      viewBox: `0 0 ${width} ${height}`,
      role: "img",
      "aria-label": "Gráfico de barras"
    });
    svg.classList.add("enem-svg-chart");

    labels.forEach((label, index) => {
      const value = values[index];
      const y = top + index * rowHeight;
      const trackY = y + 19;
      const currentWidth = value === null ? 0 : Math.max(0, Math.min(barWidth, (value / maxValue) * barWidth));

      const labelText = svgElement("text", {
        x: left - 12,
        y: trackY + 11,
        "text-anchor": "end",
        class: "enem-svg-label"
      });
      labelText.textContent = label;
      svg.appendChild(labelText);

      svg.appendChild(svgElement("rect", {
        x: left,
        y: trackY,
        width: barWidth,
        height: 20,
        rx: 7,
        class: "enem-svg-track"
      }));

      svg.appendChild(svgElement("rect", {
        x: left,
        y: trackY,
        width: currentWidth,
        height: 20,
        rx: 7,
        class: "enem-svg-bar"
      }));

      const valueText = svgElement("text", {
        x: left + barWidth + 12,
        y: trackY + 15,
        class: "enem-svg-value"
      });
      valueText.textContent = formatValue(value, suffix);
      svg.appendChild(valueText);
    });

    container.appendChild(svg);
  }

  function renderLineChart(container, payload) {
    clear(container);

    const labels = payload.labels || [];
    const values = (payload.values || []).map(number);
    const suffix = payload.suffix || "";
    const points = values
      .map((value, index) => ({ value, index }))
      .filter(item => item.value !== null);

    if (points.length < 1) {
      container.textContent = "Sem dados para exibir.";
      return;
    }

    const width = Math.max(container.clientWidth || 800, 600);
    const height = 360;
    const left = 62;
    const right = 30;
    const top = 26;
    const bottom = 54;
    const plotWidth = width - left - right;
    const plotHeight = height - top - bottom;

    const rawMin = Math.min(...points.map(p => p.value));
    const rawMax = Math.max(...points.map(p => p.value));
    const padding = Math.max((rawMax - rawMin) * 0.15, rawMax === rawMin ? Math.max(rawMax * 0.08, 1) : 1);
    const min = Math.max(0, rawMin - padding);
    const max = rawMax + padding;
    const range = Math.max(max - min, 1);

    const x = index => left + (labels.length <= 1 ? plotWidth / 2 : (index / (labels.length - 1)) * plotWidth);
    const y = value => top + plotHeight - ((value - min) / range) * plotHeight;

    const svg = svgElement("svg", {
      viewBox: `0 0 ${width} ${height}`,
      role: "img",
      "aria-label": "Gráfico de evolução histórica"
    });
    svg.classList.add("enem-svg-chart");

    for (let i = 0; i <= 4; i += 1) {
      const gridY = top + (i / 4) * plotHeight;
      const gridValue = max - (i / 4) * range;

      svg.appendChild(svgElement("line", {
        x1: left,
        y1: gridY,
        x2: width - right,
        y2: gridY,
        class: "enem-svg-grid"
      }));

      const axisLabel = svgElement("text", {
        x: left - 10,
        y: gridY + 4,
        "text-anchor": "end",
        class: "enem-svg-axis-label"
      });
      axisLabel.textContent = formatValue(gridValue, suffix);
      svg.appendChild(axisLabel);
    }

    labels.forEach((label, index) => {
      const labelText = svgElement("text", {
        x: x(index),
        y: height - 20,
        "text-anchor": "middle",
        class: "enem-svg-axis-label"
      });
      labelText.textContent = label;
      svg.appendChild(labelText);
    });

    const pointString = points.map(p => `${x(p.index)},${y(p.value)}`).join(" ");
    svg.appendChild(svgElement("polyline", {
      points: pointString,
      fill: "none",
      class: "enem-svg-line"
    }));

    points.forEach(point => {
      const circle = svgElement("circle", {
        cx: x(point.index),
        cy: y(point.value),
        r: 5,
        class: "enem-svg-point"
      });
      svg.appendChild(circle);

      const valueText = svgElement("text", {
        x: x(point.index),
        y: y(point.value) - 12,
        "text-anchor": "middle",
        class: "enem-svg-value"
      });
      valueText.textContent = formatValue(point.value, suffix);
      svg.appendChild(valueText);
    });

    container.appendChild(svg);
  }

  function renderAll() {
    document.querySelectorAll("[data-enem-chart-type]").forEach(container => {
      const payload = parsePayload(container);
      const type = container.dataset.enemChartType;

      if (type === "line") {
        renderLineChart(container, payload);
      } else {
        renderBarChart(container, payload);
      }
    });
  }

  let resizeTimer;

  document.addEventListener("DOMContentLoaded", renderAll);
  document.addEventListener("turbo:load", renderAll);

  window.addEventListener("resize", () => {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(renderAll, 150);
  });
})();
