// AshCharts JavaScript Hook for Chart.js integration
// This file should be imported into your Phoenix LiveView application

import {
  Chart,
  ArcElement,
  LineElement,
  BarElement,
  PointElement,
  BarController,
  BubbleController,
  DoughnutController,
  LineController,
  PieController,
  PolarAreaController,
  RadarController,
  ScatterController,
  CategoryScale,
  LinearScale,
  LogarithmicScale,
  RadialLinearScale,
  TimeScale,
  TimeSeriesScale,
  Decimation,
  Filler,
  Legend,
  Title,
  Tooltip,
  SubTitle
} from 'chart.js';

// Register Chart.js components
Chart.register(
  ArcElement,
  LineElement,
  BarElement,
  PointElement,
  BarController,
  BubbleController,
  DoughnutController,
  LineController,
  PieController,
  PolarAreaController,
  RadarController,
  ScatterController,
  CategoryScale,
  LinearScale,
  LogarithmicScale,
  RadialLinearScale,
  TimeScale,
  TimeSeriesScale,
  Decimation,
  Filler,
  Legend,
  Title,
  Tooltip,
  SubTitle
);

/**
 * Phoenix LiveView hook for Chart.js integration
 * 
 * Usage:
 * ```javascript
 * import AshChartsHook from "ash_charts/chart_hook"
 * 
 * const liveSocket = new LiveSocket("/live", Socket, {
 *   hooks: {Chart: AshChartsHook}
 * })
 * ```
 */
const AshChartsHook = {
  mounted() {
    this.initChart();
  },

  updated() {
    // Only update if the data has actually changed
    const newData = this.el.dataset.chartData;
    if (this.chart && this.lastData !== newData) {
      this.updateChart();
      this.lastData = newData;
    } else if (!this.chart) {
      this.initChart();
    }
  },

  destroyed() {
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  },

  initChart() {
    const ctx = this.el.getContext('2d');
    const chartType = this.el.dataset.chartType;
    const chartData = JSON.parse(this.el.dataset.chartData || '{}');
    const chartTitle = this.el.dataset.chartTitle || '';
    const responsive = this.el.dataset.chartResponsive === 'true';
    const customColors = this.el.dataset.chartColors !== 'null' 
      ? JSON.parse(this.el.dataset.chartColors) 
      : null;

    // Apply custom colors if provided
    if (customColors && chartData.datasets) {
      chartData.datasets.forEach((dataset, index) => {
        if (customColors[index]) {
          dataset.backgroundColor = customColors[index];
          dataset.borderColor = customColors[index].replace('0.2', '1');
        }
      });
    }

    const config = {
      type: chartType,
      data: chartData,
      options: {
        responsive: responsive,
        maintainAspectRatio: !responsive,
        plugins: {
          title: {
            display: !!chartTitle,
            text: chartTitle,
            font: {
              size: 16,
              weight: 'bold'
            }
          },
          legend: {
            display: true,
            position: this.getLegendPosition(chartType)
          },
          tooltip: {
            mode: 'index',
            intersect: false,
          }
        },
        scales: this.getScalesConfig(chartType),
        interaction: {
          mode: 'nearest',
          axis: 'x',
          intersect: false
        }
      }
    };

    // Apply chart-type specific configurations
    this.applyChartTypeConfig(config, chartType);

    this.chart = new Chart(ctx, config);
    this.lastData = this.el.dataset.chartData;
  },

  updateChart() {
    const chartData = JSON.parse(this.el.dataset.chartData || '{}');
    const customColors = this.el.dataset.chartColors !== 'null' 
      ? JSON.parse(this.el.dataset.chartColors) 
      : null;

    // Apply custom colors if provided
    if (customColors && chartData.datasets) {
      chartData.datasets.forEach((dataset, index) => {
        if (customColors[index]) {
          dataset.backgroundColor = customColors[index];
          dataset.borderColor = customColors[index].replace('0.2', '1');
        }
      });
    }

    this.chart.data = chartData;
    this.chart.update('resize');
  },

  getScalesConfig(chartType) {
    // Pie and doughnut charts don't use scales
    if (['pie', 'doughnut', 'polarArea'].includes(chartType)) {
      return {};
    }

    return {
      x: {
        display: true,
        title: {
          display: false
        },
        grid: {
          display: true,
          color: 'rgba(0, 0, 0, 0.1)'
        }
      },
      y: {
        display: true,
        title: {
          display: false
        },
        grid: {
          display: true,
          color: 'rgba(0, 0, 0, 0.1)'
        },
        beginAtZero: true
      }
    };
  },

  getLegendPosition(chartType) {
    switch (chartType) {
      case 'pie':
      case 'doughnut':
        return 'right';
      default:
        return 'top';
    }
  },

  applyChartTypeConfig(config, chartType) {
    switch (chartType) {
      case 'line':
        config.options.elements = {
          line: {
            tension: 0.1
          },
          point: {
            radius: 3,
            hoverRadius: 5
          }
        };
        break;
      
      case 'bar':
        config.options.scales.x.grid.display = false;
        break;
      
      case 'pie':
      case 'doughnut':
        config.options.plugins.legend.position = 'right';
        break;
      
      case 'radar':
        config.options.elements = {
          line: {
            borderWidth: 3
          }
        };
        break;
    }
  }
};

export default AshChartsHook;