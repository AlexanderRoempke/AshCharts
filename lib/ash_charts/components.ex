defmodule AshCharts.Components do
  @moduledoc """
  Phoenix LiveView components for rendering interactive charts from Ash resources.
  
  This module provides reusable chart components that integrate with Ash Framework
  and Chart.js to create beautiful, interactive visualizations.
  
  ## Basic Usage
  
      <.ash_chart 
        resource={MyApp.User}
        chart_type={:bar}
        x_field={:role}
        y_field={:count}
        title="Users by Role"
      />
  
  ## Available Chart Types
  
  - `:bar` - Bar charts
  - `:line` - Line charts
  - `:pie` - Pie charts
  - `:doughnut` - Doughnut charts
  - `:radar` - Radar charts
  
  ## Convenience Components
  
  For common use cases, you can use the simplified components:
  
  - `bar_chart/1` - Quick bar charts
  - `line_chart/1` - Quick line charts  
  - `pie_chart/1` - Quick pie charts
  """
  
  use Phoenix.Component
  
  @doc """
  Renders a chart based on Ash resource data.
  
  ## Examples
  
      <.ash_chart 
        resource={MyApp.User}
        chart_type={:bar}
        x_field={:created_at}
        y_field={:count}
        title="User Registrations Over Time"
      />
      
      <.ash_chart 
        resource={MyApp.Order}
        chart_type={:line}
        x_field={:date}
        y_field={:total_amount}
        group_by={:status}
        title="Order Amounts by Status"
      />
  """
  
  attr :id, :string, default: nil, doc: "Optional chart ID"
  attr :resource, :atom, required: true, doc: "The Ash resource to query"
  attr :chart_type, :atom, default: :bar, doc: "Chart type: :bar, :line, :pie, :doughnut, :radar"
  attr :x_field, :atom, required: true, doc: "Field to use for X-axis"
  attr :y_field, :atom, required: true, doc: "Field to use for Y-axis"
  attr :group_by, :atom, default: nil, doc: "Optional field to group data by"
  attr :title, :string, default: "", doc: "Chart title"
  attr :width, :integer, default: 400, doc: "Chart width in pixels"
  attr :height, :integer, default: 300, doc: "Chart height in pixels"
  attr :query_params, :map, default: %{}, doc: "Additional query parameters for the resource"
  attr :aggregate_function, :atom, default: :count, doc: "Aggregation function: :count, :sum, :avg, :min, :max"
  attr :date_grouping, :atom, default: :day, doc: "Date grouping for time-based charts: :day, :week, :month, :year"
  attr :colors, :list, default: nil, doc: "Custom colors for the chart"
  attr :responsive, :boolean, default: true, doc: "Make chart responsive"
  attr :class, :string, default: "", doc: "Additional CSS classes"
  
  def ash_chart(assigns) do
    chart_id = assigns[:id] || "chart-#{System.unique_integer([:positive])}"
    chart_data = get_chart_data(assigns)
    
    assigns = 
      assigns
      |> assign(:chart_id, chart_id)
      |> assign(:chart_data, chart_data)
    
    ~H"""
    <div class={["chart-container", @class]} id={"#{@chart_id}-container"}>
      <canvas 
        id={@chart_id}
        width={@width}
        height={@height}
        phx-hook="Chart"
        data-chart-type={@chart_type}
        data-chart-data={Jason.encode!(@chart_data)}
        data-chart-title={@title}
        data-chart-responsive={@responsive}
        data-chart-colors={if @colors, do: Jason.encode!(@colors), else: "null"}
      >
      </canvas>
    </div>
    """
  end
  
  @doc """
  Simplified bar chart component for quick use.
  """
  attr :resource, :atom, required: true
  attr :x_field, :atom, required: true
  attr :y_field, :atom, required: true
  attr :title, :string, default: ""
  attr :class, :string, default: ""
  
  def bar_chart(assigns) do
    ~H"""
    <.ash_chart 
      resource={@resource}
      chart_type={:bar}
      x_field={@x_field}
      y_field={@y_field}
      title={@title}
      class={@class}
    />
    """
  end
  
  @doc """
  Simplified line chart component for time series data.
  """
  attr :resource, :atom, required: true
  attr :x_field, :atom, required: true
  attr :y_field, :atom, required: true
  attr :title, :string, default: ""
  attr :date_grouping, :atom, default: :day
  attr :class, :string, default: ""
  
  def line_chart(assigns) do
    ~H"""
    <.ash_chart 
      resource={@resource}
      chart_type={:line}
      x_field={@x_field}
      y_field={@y_field}
      title={@title}
      date_grouping={@date_grouping}
      class={@class}
    />
    """
  end
  
  @doc """
  Simplified pie chart component.
  """
  attr :resource, :atom, required: true
  attr :label_field, :atom, required: true
  attr :value_field, :atom, required: true
  attr :title, :string, default: ""
  attr :class, :string, default: ""
  
  def pie_chart(assigns) do
    ~H"""
    <.ash_chart 
      resource={@resource}
      chart_type={:pie}
      x_field={@label_field}
      y_field={@value_field}
      title={@title}
      class={@class}
    />
    """
  end
  
  defp get_chart_data(assigns) do
    # In a real implementation, this would fetch data from the Ash resource
    # For now, we'll delegate to the data helper
    AshCharts.DataHelper.process_data(%{
      resource: assigns.resource,
      x_field: assigns.x_field,
      y_field: assigns.y_field,
      group_by: assigns.group_by,
      query_params: assigns.query_params,
      aggregate_function: assigns.aggregate_function,
      date_grouping: assigns.date_grouping,
      chart_type: assigns.chart_type
    })
  end
end