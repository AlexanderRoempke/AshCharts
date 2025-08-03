defmodule Mix.Tasks.Tapir.Install do
  @moduledoc """
  Installs Tapir chart components with automatic setup.

  This task:
  1. Adds Chart.js to package.json 
  2. Copies the Chart.js hook to assets/js/
  3. Updates app.js to import the hook
  4. Adds component imports to the web module
  5. Sets up npm install in mix aliases

  ## Usage

      mix tapir.install

  ## Options

    * `--no-assets` - Skip assets and JavaScript setup
    * `--no-deps` - Skip adding dependencies to mix.exs
  """

  use Mix.Task
  
  def run(argv) do
    if "--yes" in argv do
      System.put_env("IGNITER_ASSUME_YES", "true")
    end
    
    Igniter.new()
    |> igniter(argv)
    |> Igniter.do_or_dry_run(argv)
  end


  def igniter(igniter, argv) do
    # Parse options from args
    options = OptionParser.parse(argv, strict: [no_assets: :boolean, no_deps: :boolean, yes: :boolean]) |> elem(0)

    igniter
    |> setup_assets(options)
    |> setup_web_module(options)
    |> setup_mix_aliases(options)
  end

  defp setup_dependencies(igniter, options) do
    if options[:no_deps] do
      igniter
    else
      igniter
      |> Igniter.Project.Deps.add_dep({:tapir, "~> 0.1"})
      |> Igniter.Project.Deps.add_dep({:ash, "~> 3.0"}, if_not_exists: true)
    end
  end

  defp setup_assets(igniter, options) do
    if options[:no_assets] do
      igniter
    else
      igniter
      |> setup_package_json()
      |> setup_chart_hook()
      |> setup_app_js()
    end
  end

  defp setup_package_json(igniter) do
    package_json_path = "assets/package.json"
    
    # Always create or update package.json
    package_json_content = Jason.encode!(%{
      "dependencies" => %{
        "chart.js" => "^4.5.0"
      }
    }, pretty: true)
    
    igniter
    |> Igniter.create_or_update_file(package_json_path, package_json_content, fn existing_content ->
      case Jason.decode(existing_content) do
        {:ok, json} ->
          updated_json = 
            json
            |> Map.put_new("dependencies", %{})
            |> put_in(["dependencies", "chart.js"], "^4.5.0")
          
          Jason.encode!(updated_json, pretty: true)
        {:error, _} ->
          package_json_content
      end
    end)
  end

  defp setup_chart_hook(igniter) do
    hook_path = "assets/js/chart_hook.js"
    
    hook_content = """
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
 * Phoenix LiveView hook for Chart.js integration via Tapir
 */
const TapirChartHook = {
  mounted() {
    this.initChart();
  },

  updated() {
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
            font: { size: 16, weight: 'bold' }
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

    this.applyChartTypeConfig(config, chartType);
    this.chart = new Chart(ctx, config);
    this.lastData = this.el.dataset.chartData;
  },

  updateChart() {
    const chartData = JSON.parse(this.el.dataset.chartData || '{}');
    const customColors = this.el.dataset.chartColors !== 'null' 
      ? JSON.parse(this.el.dataset.chartColors) 
      : null;

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
    if (['pie', 'doughnut', 'polarArea'].includes(chartType)) {
      return {};
    }

    return {
      x: {
        display: true,
        title: { display: false },
        grid: { display: true, color: 'rgba(0, 0, 0, 0.1)' }
      },
      y: {
        display: true,
        title: { display: false },
        grid: { display: true, color: 'rgba(0, 0, 0, 0.1)' },
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
          line: { tension: 0.1 },
          point: { radius: 3, hoverRadius: 5 }
        };
        break;
      
      case 'bar':
        config.options.scales.x.grid.display = false;
        break;
      
      case 'radar':
        config.options.elements = {
          line: { borderWidth: 3 }
        };
        break;
    }
  }
};

export default TapirChartHook;
"""
    
    Igniter.create_new_file(igniter, hook_path, hook_content)
  end

  defp setup_app_js(igniter) do
    app_js_path = "assets/js/app.js"
    
    igniter
    |> Igniter.update_file(app_js_path, fn content ->
      content_with_import = 
        if String.contains?(content, "TapirChartHook") do
          content
        else
          # Add import at the top with other imports
          lines = String.split(content, "\\n")
          import_line = "import TapirChartHook from \"./chart_hook\""
          
          # Find position after last import
          {before_imports, rest} = 
            Enum.split_while(lines, fn line ->
              String.starts_with?(String.trim(line), "import") or 
              String.trim(line) == "" or
              String.starts_with?(String.trim(line), "//")
            end)
          
          (before_imports ++ [import_line] ++ rest)
          |> Enum.join("\\n")
        end
      
      # Update hooks configuration - handle different patterns
      cond do
        String.contains?(content_with_import, "Chart:") ->
          content_with_import
        
        String.contains?(content_with_import, "hooks:") ->
          # Add Chart hook to existing hooks
          String.replace(content_with_import, ~r/hooks:\s*\{/, "hooks: {Chart: TapirChartHook, ")
        
        true ->
          # Add hooks to LiveSocket config
          String.replace(content_with_import, 
            ~r/(new LiveSocket\([^,]+,\s*[^,]+,\s*)\{/,
            "\\1{\\n  hooks: {Chart: TapirChartHook},"
          )
      end
    end)
  end

  defp setup_web_module(igniter, _options) do
    # This is a simplified approach - just show instructions to user
    # Finding and modifying the web module programmatically is complex
    igniter
  end

  defp setup_mix_aliases(igniter, options) do
    if options[:no_assets] do
      igniter
    else
      # Update mix.exs to add npm install to assets.setup
      igniter
      |> Igniter.update_file("mix.exs", fn content ->
        # Add npm install to assets.setup if not already present
        if String.contains?(content, "npm install --prefix assets") do
          content
        else
          content
          |> String.replace(
            ~r/"assets.setup": \[([^\]]*)\]/,
            fn match ->
              if String.contains?(match, "npm install") do
                match
              else
                String.replace(match, "]", ", \"cmd npm install --prefix assets\"]")
              end
            end
          )
        end
      end)
    end
  end
end