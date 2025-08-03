# AshCharts

[![Hex.pm](https://img.shields.io/hexpm/v/ash_charts.svg)](https://hex.pm/packages/ash_charts)
[![Documentation](https://img.shields.io/badge/documentation-hexdocs-blue.svg)](https://hexdocs.pm/ash_charts)
[![License](https://img.shields.io/hexpm/l/ash_charts.svg)](LICENSE)

A reusable chart library for [Ash Framework](https://ash-hq.org/) applications with Phoenix LiveView integration. Create beautiful, interactive charts directly from your Ash resources using [Chart.js](https://www.chartjs.org/).

## Features

- 🚀 **Easy Integration**: Works seamlessly with Ash resources
- 📊 **Multiple Chart Types**: Bar, Line, Pie, Doughnut, and Radar charts
- 🎨 **Customizable**: Configurable colors, styling, and chart options
- 📱 **Responsive**: Charts adapt to different screen sizes
- ⚡ **Real-time**: LiveView integration for dynamic updates
- 🔧 **Flexible**: Supports grouping, aggregation, and date grouping
- 🛡️ **Type Safe**: Full Elixir type specs and documentation

## Installation

Add `ash_charts` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_charts, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Setup

### 1. Install Chart.js

In your Phoenix application's assets directory:

```bash
cd assets
npm install chart.js
```

### 2. Import Components

Add the chart components to your web module:

```elixir
# In lib/my_app_web.ex
defp html_helpers do
  quote do
    # Your existing imports...
    import AshCharts.Components
  end
end
```

### 3. Add JavaScript Hook

Import and register the chart hook in your `app.js`:

```javascript
// In assets/js/app.js
import AshChartsHook from "ash_charts/chart_hook"

const liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: {Chart: AshChartsHook, ...otherHooks}
})
```

## Quick Start

### Basic Bar Chart

```elixir
<.ash_chart 
  resource={MyApp.User}
  chart_type={:bar}
  x_field={:role}
  y_field={:count}
  title="Users by Role"
/>
```

### Line Chart with Time Grouping

```elixir
<.ash_chart 
  resource={MyApp.Order}
  chart_type={:line}
  x_field={:created_at}
  y_field={:total_amount}
  date_grouping={:month}
  title="Revenue Over Time"
/>
```

### Pie Chart

```elixir
<.ash_chart 
  resource={MyApp.Product}
  chart_type={:pie}
  x_field={:category}
  y_field={:sales}
  title="Sales by Category"
/>
```

## Component Options

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `resource` | `atom` | **required** | The Ash resource to query |
| `chart_type` | `atom` | `:bar` | Chart type: `:bar`, `:line`, `:pie`, `:doughnut`, `:radar` |
| `x_field` | `atom` | **required** | Field to use for X-axis |
| `y_field` | `atom` | **required** | Field to use for Y-axis |
| `group_by` | `atom` | `nil` | Optional field to group data by |
| `title` | `string` | `""` | Chart title |
| `width` | `integer` | `400` | Chart width in pixels |
| `height` | `integer` | `300` | Chart height in pixels |
| `query_params` | `map` | `%{}` | Additional query parameters |
| `aggregate_function` | `atom` | `:count` | Aggregation: `:count`, `:sum`, `:avg`, `:min`, `:max` |
| `date_grouping` | `atom` | `:day` | Date grouping: `:day`, `:week`, `:month`, `:year` |
| `colors` | `list` | `nil` | Custom colors for the chart |
| `responsive` | `boolean` | `true` | Make chart responsive |
| `class` | `string` | `""` | Additional CSS classes |

## Advanced Usage

### Grouped Data

```elixir
<.ash_chart 
  resource={MyApp.Sale}
  chart_type={:bar}
  x_field={:month}
  y_field={:revenue}
  group_by={:region}
  aggregate_function={:sum}
  title="Monthly Revenue by Region"
/>
```

### Custom Colors

```elixir
<.ash_chart 
  resource={MyApp.Product}
  chart_type={:doughnut}
  x_field={:category}
  y_field={:stock}
  colors={["#FF6B6B", "#4ECDC4", "#45B7D1", "#F9CA24"]}
  title="Inventory by Category"
/>
```

## Documentation

Full documentation can be found at [https://hexdocs.pm/ash_charts](https://hexdocs.pm/ash_charts).

