defmodule Tapir do
  @moduledoc """
  A reusable chart library for Ash Framework applications.

  Tapir provides Phoenix LiveView components that make it easy to create
  interactive charts from your Ash resources using Chart.js.

  ## Features

  - 🚀 **Easy Integration**: Works seamlessly with Ash resources
  - 📊 **Multiple Chart Types**: Bar, Line, Pie, Doughnut, and Radar charts
  - 🎨 **Customizable**: Configurable colors, styling, and chart options
  - 📱 **Responsive**: Charts adapt to different screen sizes
  - ⚡ **Real-time**: LiveView integration for dynamic updates
  - 🔧 **Flexible**: Supports grouping, aggregation, and date grouping

  ## Installation

  Add `tapir` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:tapir, "~> 0.1.0"}
    ]
  end
  ```

  ## Setup

  1. **Install Chart.js** in your Phoenix app:
     ```bash
     cd assets && npm install chart.js
     ```

  2. **Import the components** in your web module:
     ```elixir
     # In your_app_web.ex
     defp html_helpers do
       quote do
         # Your existing imports...
         import Tapir.Components
       end
     end
     ```

  3. **Add the JavaScript hook** to your app.js:
     ```javascript
     // In assets/js/app.js
     import TapirHook from "tapir/chart_hook"

     const liveSocket = new LiveSocket("/live", Socket, {
       hooks: {Chart: TapirHook, ...otherHooks}
     })
     ```

  ## Quick Start

  ```elixir
  # Simple bar chart
  <.ash_chart 
    resource={MyApp.User}
    chart_type={:bar}
    x_field={:role}
    y_field={:count}
    title="Users by Role"
  />

  # Line chart with time grouping
  <.ash_chart 
    resource={MyApp.Order}
    chart_type={:line}
    x_field={:created_at}
    y_field={:total_amount}
    date_grouping={:month}
    title="Revenue Over Time"
  />

  # Pie chart
  <.ash_chart 
    resource={MyApp.Product}
    chart_type={:pie}
    x_field={:category}
    y_field={:sales}
    title="Sales by Category"
  />
  ```

  ## Components

  - `Tapir.Components` - Main chart components
  - `Tapir.DataHelper` - Data transformation utilities
  - `Tapir.Helpers` - Helper functions for common operations

  For detailed documentation, see the individual modules.
  """

  @doc false
  def version, do: unquote(Mix.Project.config()[:version])
end
