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

  describe "maybe_apply_filters private function" do
    test "filter syntax compiles without error" do
      # This test will fail if there are syntax errors in the filtering code
      # We can't directly test the private function, but we can test that
      # the module compiles and the filter syntax is valid
      
      # Test that we can at least call process_data without crashing
      # even with invalid resource (should return empty data)
      params = %{
        resource: NonExistentResource,
        x_field: :name,
        y_field: :value,
        query_params: %{
          filter: %{category: "A"}
        }
      }

      result = Tapir.DataHelper.process_data(params)
      
      # Should return empty data due to invalid resource, but not crash due to filter syntax
      assert %{labels: [], datasets: [%{data: []}]} = result
    end
  end
end