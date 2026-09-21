<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { Chart, LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Legend } from 'chart.js'

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Legend)

// Thin Chart.js wrapper — the only place in the app that touches the Chart.js
// API directly, same "one wrapper per third-party primitive" convention as
// every OpenVue component under components/base/. `datasets` follows Chart.js's
// own shape ([{ label, data, ... }]) minus color, which this component applies
// itself (reading the app's own CSS custom properties so a chart always matches
// the current theme, light or dark, without the caller hardcoding hex values).
const props = defineProps({
  labels: { type: Array, required: true },
  datasets: { type: Array, required: true },
  // (value, datasetLabel) => string — exact tooltip text; callers format with
  // formatNumber/formatCurrency/etc. so a chart never invents its own rounding.
  formatValue: { type: Function, default: (value) => value },
})

const canvasRef = ref(null)
let chart = null

function themeColor(varName, fallback) {
  const value = getComputedStyle(document.documentElement).getPropertyValue(varName).trim()
  return value || fallback
}

// Only non-semantic tokens — success/warning/danger are reserved for state
// communication (component-design.md), not decorative use as chart-series
// colors. --color-info reads as a second neutral/informational accent rather
// than a "state," so it's the one semantic-adjacent token safe to reuse here.
const PALETTE = ['--color-primary', '--color-info']

function styledDatasets() {
  return props.datasets.map((dataset, i) => {
    const color = themeColor(PALETTE[i % PALETTE.length], '#185fa5')
    return {
      borderColor: color,
      backgroundColor: color,
      pointBackgroundColor: color,
      pointRadius: 2,
      pointHoverRadius: 4,
      borderWidth: 2,
      tension: 0.3,
      fill: false,
      ...dataset,
    }
  })
}

function buildOptions() {
  const textMuted = themeColor('--color-text-muted', '#64748b')
  const border = themeColor('--color-border', '#e2e8f0')

  // A second, independent scale only when a caller actually needs one (e.g. a
  // count alongside a currency amount, wildly different magnitudes) — opted
  // into per-dataset via `yAxisID: 'y1'`, otherwise every series shares one
  // axis. y1 has no grid of its own so it doesn't visually compete with y's.
  const hasSecondAxis = props.datasets.some((d) => d.yAxisID === 'y1')

  const scales = {
    x: { grid: { display: false }, ticks: { color: textMuted } },
    y: { grid: { color: border }, ticks: { color: textMuted }, beginAtZero: true },
  }
  if (hasSecondAxis) {
    scales.y1 = { position: 'right', grid: { display: false }, ticks: { color: textMuted }, beginAtZero: true }
  }

  return {
    responsive: true,
    maintainAspectRatio: false,
    interaction: { mode: 'index', intersect: false },
    plugins: {
      legend: { display: props.datasets.length > 1, labels: { color: textMuted, usePointStyle: true, boxHeight: 6 } },
      tooltip: {
        callbacks: {
          label: (context) => `${context.dataset.label}: ${props.formatValue(context.parsed.y, context.dataset.label)}`,
        },
      },
    },
    scales,
  }
}

onMounted(() => {
  chart = new Chart(canvasRef.value, {
    type: 'line',
    data: { labels: props.labels, datasets: styledDatasets() },
    options: buildOptions(),
  })
})

onUnmounted(() => {
  chart?.destroy()
})

watch(
  () => [props.labels, props.datasets],
  () => {
    if (!chart) return
    chart.data.labels = props.labels
    chart.data.datasets = styledDatasets()
    chart.update()
  },
  { deep: true },
)
</script>

<template>
  <div class="base-chart">
    <canvas ref="canvasRef" role="img" />
  </div>
</template>

<style scoped>
.base-chart {
  position: relative;
  height: 16rem;
  width: 100%;
}
</style>
