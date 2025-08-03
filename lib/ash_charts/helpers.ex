defmodule AshCharts.Helpers do
  @moduledoc """
  Helper functions for working with charts and data.
  
  This module provides utilities for creating charts from Ash resources
  and handling common chart operations.
  """
  
  @doc """
  Creates a chart component with real Ash data.
  
  This is an example of how to use the chart library with actual data
  instead of static demo data.
  
  ## Example
  
      # In your LiveView
      def mount(_params, _session, socket) do
        chart_data = AshCharts.Helpers.fetch_chart_data(MyApp.User, %{
          x_field: :role,
          y_field: :count,
          aggregate_function: :count
        })
        socket = assign(socket, :user_chart_data, chart_data)
        {:ok, socket}
      end
      
      # In your template
      <.chart_with_data 
        data={@user_chart_data}
        chart_type={:bar}
        title="User Statistics"
      />
  """
  def fetch_chart_data(resource, opts \\ %{}) do
    case AshCharts.DataHelper.process_data(Map.put(opts, :resource, resource)) do
      %{labels: [], datasets: []} -> get_empty_chart_data()
      chart_data -> chart_data
    end
  end
  
  @doc """
  Transforms Ash resource data into Chart.js format.
  
  This is a utility function that can be used to convert
  query results from Ash into the format expected by Chart.js.
  """
  def transform_data_for_chart(data, opts \\ []) do
    label_field = Keyword.get(opts, :label_field, :name)
    value_field = Keyword.get(opts, :value_field, :count)
    
    {labels, values} = 
      data
      |> Enum.map(fn item ->
        label = Map.get(item, label_field)
        value = Map.get(item, value_field, 0)
        {to_string(label), value}
      end)
      |> Enum.unzip()
    
    %{
      labels: labels,
      datasets: [
        %{
          label: humanize_field(value_field),
          data: values,
          backgroundColor: generate_colors(length(values), 0.2),
          borderColor: generate_colors(length(values), 1.0),
          borderWidth: 1
        }
      ]
    }
  end
  
  @doc """
  Returns empty chart data structure for error states.
  """
  def get_empty_chart_data do
    %{
      labels: [],
      datasets: [
        %{
          label: "No Data",
          data: [],
          backgroundColor: [],
          borderColor: [],
          borderWidth: 1
        }
      ]
    }
  end
  
  @doc """
  Generates a color palette for charts.
  
  ## Examples
  
      iex> AshCharts.Helpers.generate_colors(3, 0.2)
      ["rgba(255, 99, 132, 0.2)", "rgba(54, 162, 235, 0.2)", "rgba(255, 205, 86, 0.2)"]
  """
  def generate_colors(count, alpha \\ 0.2) do
    base_colors = [
      {255, 99, 132},   # Red
      {54, 162, 235},   # Blue
      {255, 205, 86},   # Yellow
      {75, 192, 192},   # Teal
      {153, 102, 255},  # Purple
      {255, 159, 64},   # Orange
      {199, 199, 199},  # Gray
      {83, 102, 255}    # Indigo
    ]
    
    base_colors
    |> Stream.cycle()
    |> Enum.take(count)
    |> Enum.map(fn {r, g, b} -> "rgba(#{r}, #{g}, #{b}, #{alpha})" end)
  end
  
  @doc """
  Converts a field name to a human-readable label.
  
  ## Examples
  
      iex> AshCharts.Helpers.humanize_field(:total_amount)
      "Total Amount"
      
      iex> AshCharts.Helpers.humanize_field("user_count")
      "User Count"
  """
  def humanize_field(field) when is_atom(field) do
    field
    |> to_string()
    |> humanize_field()
  end
  
  def humanize_field(field) when is_binary(field) do
    field
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  
  @doc """
  Creates chart configuration for different chart types.
  
  This helper can be used to generate chart.js configuration
  objects with sensible defaults for different chart types.
  """
  def chart_config(type, data, opts \\ []) do
    title = Keyword.get(opts, :title, "")
    responsive = Keyword.get(opts, :responsive, true)
    
    base_config = %{
      type: type,
      data: data,
      options: %{
        responsive: responsive,
        maintainAspectRatio: !responsive,
        plugins: %{
          title: %{
            display: title != "",
            text: title,
            font: %{size: 16, weight: "bold"}
          },
          legend: %{
            display: true,
            position: get_legend_position(type)
          }
        }
      }
    }
    
    case type do
      type when type in [:pie, :doughnut] ->
        base_config
      _ ->
        put_in(base_config, [:options, :scales], %{
          x: %{display: true, grid: %{display: true}},
          y: %{display: true, grid: %{display: true}, beginAtZero: true}
        })
    end
  end
  
  defp get_legend_position(:pie), do: "right"
  defp get_legend_position(:doughnut), do: "right"
  defp get_legend_position(_), do: "top"
end