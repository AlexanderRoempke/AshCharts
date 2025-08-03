defmodule AshCharts.DataHelper do
  @moduledoc """
  Helper module for processing Ash resource data into chart-ready format.
  
  This module handles the transformation of data from Ash resources into
  the format expected by Chart.js for rendering charts.
  """
  
  import Ash.Query
  
  @doc """
  Processes data from an Ash resource for chart rendering.
  
  ## Parameters
  
  - `resource` - The Ash resource to query
  - `x_field` - Field to use for X-axis/labels
  - `y_field` - Field to use for Y-axis/values
  - `group_by` - Optional field to group data by
  - `query_params` - Additional filters for the query
  - `aggregate_function` - How to aggregate data (:count, :sum, :avg, etc.)
  - `date_grouping` - How to group date fields (:day, :week, :month, :year)
  - `chart_type` - Type of chart being created
  
  ## Returns
  
  A map with the structure expected by Chart.js:
  
      %{
        labels: ["Label 1", "Label 2", "Label 3"],
        datasets: [
          %{
            label: "Dataset Name",
            data: [10, 20, 30],
            backgroundColor: ["color1", "color2", "color3"],
            borderColor: ["color1", "color2", "color3"],
            borderWidth: 1
          }
        ]
      }
  """
  def process_data(%{resource: resource} = params) do
    try do
      case fetch_resource_data(resource, params) do
        {:ok, data} when is_list(data) ->
          transform_for_chart(data, params)
        {:ok, _data} ->
          get_empty_chart_data()
        {:error, _error} ->
          get_empty_chart_data()
      end
    rescue
      _ ->
        get_empty_chart_data()
    end
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
  Transforms a list of data into Chart.js format.
  
  ## Examples
  
      iex> data = [%{name: "A", value: 10}, %{name: "B", value: 20}]
      iex> params = %{x_field: :name, y_field: :value}
      iex> AshCharts.DataHelper.transform_for_chart(data, params)
      %{
        labels: ["A", "B"],
        datasets: [%{label: "Value", data: [10, 20], ...}]
      }
  """
  def transform_for_chart(data, params) when is_list(data) do
    if params[:group_by] do
      transform_grouped_data(data, params)
    else
      transform_simple_data(data, params)
    end
  end
  
  defp fetch_resource_data(resource, params) do
    query = 
      resource
      |> new()
      |> apply_query_params(params[:query_params] || %{})
      |> build_aggregation_query(params)
    
    case Ash.read(query) do
      {:ok, results} -> {:ok, results}
      error -> error
    end
  end
  
  defp apply_query_params(query, params) when params == %{}, do: query
  defp apply_query_params(query, params) do
    # Apply filtering based on query params
    # This is a simplified implementation - in production you'd want more robust filtering
    Enum.reduce(params, query, fn {field, value}, acc ->
      where(acc, ^ref(field) == ^value)
    end)
  end
  
  defp build_aggregation_query(query, params) do
    # For production use, implement proper Ash aggregations here
    # This is a placeholder that returns the basic query
    query
  end
  
  defp transform_simple_data(data, params) do
    {labels, values} = 
      data
      |> Enum.map(fn item ->
        x_value = format_label(Map.get(item, params[:x_field]), params)
        y_value = Map.get(item, params[:y_field]) || 0
        {x_value, y_value}
      end)
      |> Enum.sort_by(fn {label, _value} -> label end)
      |> Enum.unzip()
    
    %{
      labels: labels,
      datasets: [
        %{
          label: humanize_field(params[:y_field]),
          data: values,
          backgroundColor: default_colors(length(values)),
          borderColor: default_border_colors(length(values)),
          borderWidth: 1
        }
      ]
    }
  end
  
  defp transform_grouped_data(data, params) do
    grouped = 
      data
      |> Enum.group_by(fn item -> Map.get(item, params[:group_by]) end)
    
    labels = 
      data
      |> Enum.map(fn item -> format_label(Map.get(item, params[:x_field]), params) end)
      |> Enum.uniq()
      |> Enum.sort()
    
    datasets = 
      grouped
      |> Enum.with_index()
      |> Enum.map(fn {{group_value, group_data}, index} ->
        data_map = 
          group_data
          |> Enum.map(fn item ->
            x_value = format_label(Map.get(item, params[:x_field]), params)
            y_value = Map.get(item, params[:y_field]) || 0
            {x_value, y_value}
          end)
          |> Map.new()
        
        values = Enum.map(labels, fn label -> Map.get(data_map, label, 0) end)
        
        %{
          label: to_string(group_value),
          data: values,
          backgroundColor: default_colors(1, index),
          borderColor: default_border_colors(1, index),
          borderWidth: 1
        }
      end)
    
    %{
      labels: labels,
      datasets: datasets
    }
  end
  
  defp format_label(value, params) when is_struct(value, Date) do
    case params[:date_grouping] do
      :day -> Date.to_string(value)
      :week -> "Week #{Date.beginning_of_week(value) |> Date.to_string()}"
      :month -> "#{Date.beginning_of_month(value).year}-#{String.pad_leading(to_string(value.month), 2, "0")}"
      :year -> to_string(value.year)
      _ -> Date.to_string(value)
    end
  end
  
  defp format_label(value, params) when is_struct(value, DateTime) do
    value
    |> DateTime.to_date()
    |> format_label(params)
  end
  
  defp format_label(value, _params), do: to_string(value)
  
  defp humanize_field(field) when is_atom(field) do
    field
    |> to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
  
  defp default_colors(count, offset \\ 0) do
    base_colors = [
      "rgba(54, 162, 235, 0.2)",
      "rgba(255, 99, 132, 0.2)",
      "rgba(255, 205, 86, 0.2)",
      "rgba(75, 192, 192, 0.2)",
      "rgba(153, 102, 255, 0.2)",
      "rgba(255, 159, 64, 0.2)",
      "rgba(199, 199, 199, 0.2)",
      "rgba(83, 102, 255, 0.2)"
    ]
    
    base_colors
    |> Stream.cycle()
    |> Stream.drop(offset)
    |> Enum.take(count)
  end
  
  defp default_border_colors(count, offset \\ 0) do
    base_colors = [
      "rgba(54, 162, 235, 1)",
      "rgba(255, 99, 132, 1)",
      "rgba(255, 205, 86, 1)",
      "rgba(75, 192, 192, 1)",
      "rgba(153, 102, 255, 1)",
      "rgba(255, 159, 64, 1)",
      "rgba(199, 199, 199, 1)",
      "rgba(83, 102, 255, 1)"
    ]
    
    base_colors
    |> Stream.cycle()
    |> Stream.drop(offset)
    |> Enum.take(count)
  end
end