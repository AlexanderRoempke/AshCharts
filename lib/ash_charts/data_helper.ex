defmodule Tapir.DataHelper do
  @moduledoc """
  Helper module for processing Ash resource data into chart-ready format.
  
  This module handles the transformation of data from Ash resources into
  the format expected by Chart.js for rendering charts.
  """
  
  import Ash.Query
  import Ash.Expr
  
  @doc """
  Processes data from an Ash resource for chart rendering.
  
  ## Parameters
  
  - `resource` - The Ash resource to query
  - `x_field` - Field to use for X-axis/labels
  - `y_field` - Field to use for Y-axis/values
  - `group_by` - Optional field to group data by
  - `query_params` - Additional filters, sorting, and loading for the query
  - `aggregate_function` - How to aggregate data (:count, :sum, :avg, etc.)
  - `date_grouping` - How to group date fields (:day, :week, :month, :year)
  - `chart_type` - Type of chart being created
  
  ## Filtering Examples
  
  The `query_params.filter` supports comprehensive Ash filtering:
  
      # Simple equality
      filter: %{status: "active", category: "important"}
      
      # Comparison operators  
      filter: %{
        count: %{greater_than: 0},
        score: %{greater_than_or_equal: 50},
        age: %{less_than: 65},
        rating: %{less_than_or_equal: 5.0},
        status: %{not_equal: "deleted"}
      }
      
      # String operations
      filter: %{
        name: %{starts_with: "John"},
        email: %{ends_with: "@company.com"},
        description: %{contains: "important"},
        title: %{like: "%Manager%"},
        search: %{ilike: "%keyword%"}  # case-insensitive
      }
      
      # Null checks
      filter: %{
        deleted_at: %{is_nil: true},
        confirmed_at: %{is_nil: false}
      }
      
      # List operations
      filter: %{
        status: ["active", "pending", "approved"],      # shorthand for "in"
        category_id: %{in: [1, 2, 3]},
        role: %{not_in: ["admin", "super_admin"]}
      }
      
      # Complex mixed filters (all conditions are ANDed)
      filter: %{
        status: "active",
        score: %{greater_than: 80},
        category: ["tech", "science"],
        title: %{contains: "AI"},
        archived_at: %{is_nil: true}
      }
      
      # List of filter maps (also ANDed together)
      filter: [
        %{status: "active"},
        %{score: %{greater_than: 50}},
        %{category: ["important", "urgent"]}
      ]
  
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
      iex> result = Tapir.DataHelper.transform_for_chart(data, params)
      iex> result.labels
      ["A", "B"]
      iex> [dataset] = result.datasets
      iex> dataset.label
      "Value"
      iex> dataset.data
      [10, 20]
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
    query
    |> maybe_load_relationships(params[:load])
    |> maybe_apply_filters(params[:filter])
    |> maybe_apply_sort(params[:sort])
  end

  defp maybe_load_relationships(query, nil), do: query
  defp maybe_load_relationships(query, load) when is_list(load) do
    Ash.Query.load(query, load)
  end
  defp maybe_load_relationships(query, load) when is_atom(load) do
    Ash.Query.load(query, [load])
  end
  defp maybe_load_relationships(query, load) when is_map(load) do
    Ash.Query.load(query, load)
  end
  defp maybe_load_relationships(query, _load), do: query

  defp maybe_apply_filters(query, nil), do: query
  defp maybe_apply_filters(query, filters) when is_map(filters) do
    Enum.reduce(filters, query, fn {field, value}, acc_query ->
      apply_single_filter(acc_query, field, value)
    end)
  end
  defp maybe_apply_filters(query, filters) when is_list(filters) do
    # Support list of filter conditions that will be ANDed together
    Enum.reduce(filters, query, fn filter_map, acc_query ->
      maybe_apply_filters(acc_query, filter_map)
    end)
  end
  defp maybe_apply_filters(query, _filters), do: query

  # Handle different filter value types
  defp apply_single_filter(query, field, value) when is_map(value) do
    # Handle comparison operators: %{greater_than: 5}, %{less_than: 10}, etc.
    Enum.reduce(value, query, fn {operator, operand}, acc_query ->
      apply_comparison_filter(acc_query, field, operator, operand)
    end)
  end
  defp apply_single_filter(query, field, value) when is_list(value) do
    # Handle "in" filters: field: [val1, val2, val3]
    Ash.Query.filter(query, ^ref(field) in ^value)
  end
  defp apply_single_filter(query, field, value) do
    # Handle simple equality: field: value
    Ash.Query.filter(query, ^ref(field) == ^value)
  end

  # Handle comparison operators
  defp apply_comparison_filter(query, field, :greater_than, value) do
    Ash.Query.filter(query, ^ref(field) > ^value)
  end
  defp apply_comparison_filter(query, field, :greater_than_or_equal, value) do
    Ash.Query.filter(query, ^ref(field) >= ^value)
  end
  defp apply_comparison_filter(query, field, :less_than, value) do
    Ash.Query.filter(query, ^ref(field) < ^value)
  end
  defp apply_comparison_filter(query, field, :less_than_or_equal, value) do
    Ash.Query.filter(query, ^ref(field) <= ^value)
  end
  defp apply_comparison_filter(query, field, :not_equal, value) do
    Ash.Query.filter(query, ^ref(field) != ^value)
  end
  defp apply_comparison_filter(query, field, :is_nil, true) do
    Ash.Query.filter(query, is_nil(^ref(field)))
  end
  defp apply_comparison_filter(query, field, :is_nil, false) do
    Ash.Query.filter(query, not is_nil(^ref(field)))
  end
  defp apply_comparison_filter(query, field, :contains, value) do
    Ash.Query.filter(query, contains(^ref(field), ^value))
  end
  # String operations - these may not be supported by all data layers (e.g., ETS)
  # For ETS and other simple data layers, we fall back to contains
  defp apply_comparison_filter(query, field, :starts_with, value) do
    data_layer = query.resource.__ash_config__(:data_layer)
    
    if data_layer == Ash.DataLayer.Ets do
      # ETS doesn't support like, use contains as approximation
      Ash.Query.filter(query, contains(^ref(field), ^value))
    else
      # For SQL data layers that support like
      Ash.Query.filter(query, like(^ref(field), ^"#{value}%"))
    end
  end
  
  defp apply_comparison_filter(query, field, :ends_with, value) do
    data_layer = query.resource.__ash_config__(:data_layer)
    
    if data_layer == Ash.DataLayer.Ets do
      # ETS doesn't support like, use contains as approximation
      Ash.Query.filter(query, contains(^ref(field), ^value))
    else
      # For SQL data layers that support like
      Ash.Query.filter(query, like(^ref(field), ^"%#{value}"))
    end
  end
  
  defp apply_comparison_filter(query, field, :like, value) do
    data_layer = query.resource.__ash_config__(:data_layer)
    
    if data_layer == Ash.DataLayer.Ets do
      # ETS doesn't support like, use contains by removing wildcards
      clean_value = String.replace(value, "%", "")
      Ash.Query.filter(query, contains(^ref(field), ^clean_value))
    else
      # For SQL data layers that support like
      Ash.Query.filter(query, like(^ref(field), ^value))
    end
  end
  
  defp apply_comparison_filter(query, field, :ilike, value) do
    data_layer = query.resource.__ash_config__(:data_layer)
    
    if data_layer == Ash.DataLayer.Ets do
      # ETS doesn't support ilike, use contains (case sensitive though)
      clean_value = String.replace(value, "%", "")
      Ash.Query.filter(query, contains(^ref(field), ^clean_value))
    else
      # For SQL data layers that support ilike
      Ash.Query.filter(query, ilike(^ref(field), ^value))
    end
  end
  defp apply_comparison_filter(query, field, :in, values) when is_list(values) do
    Ash.Query.filter(query, ^ref(field) in ^values)
  end
  defp apply_comparison_filter(query, field, :not_in, values) when is_list(values) do
    Ash.Query.filter(query, ^ref(field) not in ^values)
  end
  # Fallback for unknown operators - treat as equality
  defp apply_comparison_filter(query, field, _operator, value) do
    Ash.Query.filter(query, ^ref(field) == ^value)
  end

  defp maybe_apply_sort(query, nil), do: query
  defp maybe_apply_sort(query, sort_field) when is_atom(sort_field) do
    Ash.Query.sort(query, sort_field)
  end
  defp maybe_apply_sort(query, sort_fields) when is_list(sort_fields) do
    Ash.Query.sort(query, sort_fields)
  end
  defp maybe_apply_sort(query, _sort), do: query
  
  defp build_aggregation_query(query, _params) do
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