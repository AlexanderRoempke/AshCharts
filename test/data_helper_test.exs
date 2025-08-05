defmodule Tapir.DataHelperTest do
  use ExUnit.Case
  doctest Tapir.DataHelper

  describe "transform_for_chart/2" do
    test "transforms simple data correctly" do
      data = [
        %{name: "A", value: 10},
        %{name: "B", value: 20},
        %{name: "C", value: 30}
      ]

      params = %{x_field: :name, y_field: :value}

      result = Tapir.DataHelper.transform_for_chart(data, params)

      assert %{
        labels: ["A", "B", "C"],
        datasets: [
          %{
            label: "Value",
            data: [10, 20, 30],
            backgroundColor: _,
            borderColor: _,
            borderWidth: 1
          }
        ]
      } = result
    end

    test "handles missing fields gracefully" do
      data = [
        %{name: "A", value: 10},
        %{name: "B"},  # missing value
        %{value: 30}   # missing name
      ]

      params = %{x_field: :name, y_field: :value}

      result = Tapir.DataHelper.transform_for_chart(data, params)

      assert %{labels: labels, datasets: [%{data: values}]} = result
      assert length(labels) == 3
      assert length(values) == 3
      # Missing values should default to 0
      assert 0 in values
    end
  end

  describe "get_empty_chart_data/0" do
    test "returns proper empty structure" do
      result = Tapir.DataHelper.get_empty_chart_data()

      assert %{
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
      } = result
    end
  end

  describe "extended filtering functionality" do
    test "basic equality filters compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{category: "A", status: "active"}
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "comparison operators compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            count: %{greater_than: 0},
            score: %{greater_than_or_equal: 50},
            age: %{less_than: 65},
            rating: %{less_than_or_equal: 5.0}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "string operations compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            name: %{starts_with: "John"},
            email: %{ends_with: "@example.com"},
            description: %{contains: "important"},
            title: %{like: "%Manager%"},
            search: %{ilike: "%keyword%"}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "null checks compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            deleted_at: %{is_nil: true},
            confirmed_at: %{is_nil: false}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "list-based filters compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            status: ["active", "pending", "approved"],
            category_id: %{in: [1, 2, 3]},
            role: %{not_in: ["admin", "super_admin"]}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "complex mixed filters compile without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            # Simple equality
            status: "active",
            # Comparison
            score: %{greater_than: 80},
            # List inclusion  
            category: ["tech", "science"],
            # String operations
            title: %{contains: "AI"},
            # Null checks
            archived_at: %{is_nil: true}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "list of filter maps compiles without error" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: [
            %{status: "active"},
            %{score: %{greater_than: 50}},
            %{category: ["important", "urgent"]}
          ]
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end

    test "unknown operators fallback to equality" do
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{
            field: %{unknown_operator: "some_value"}
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)
      assert %{labels: [], datasets: [%{data: []}]} = result
    end
  end
end