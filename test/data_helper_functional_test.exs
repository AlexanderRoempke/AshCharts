defmodule Tapir.DataHelperFunctionalTest do
  use ExUnit.Case

  defmodule Product do
    @moduledoc false
    use Ash.Resource,
      domain: Tapir.DataHelperFunctionalTest.TestDomain,
      data_layer: Ash.DataLayer.Ets,
      validate_domain_inclusion?: false

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id
      attribute :name, :string, allow_nil?: false
      attribute :description, :string
      attribute :price, :decimal
      attribute :rating, :float
      attribute :stock_count, :integer, default: 0
      attribute :category, :string
      attribute :status, :string, default: "active"
      attribute :created_at, :utc_datetime_usec, default: &DateTime.utc_now/0
      attribute :deleted_at, :utc_datetime_usec
      attribute :featured, :boolean, default: false
    end

    actions do
      defaults [:read, :destroy]
      
      create :create do
        accept [:name, :description, :price, :rating, :stock_count, :category, :status, :deleted_at, :featured]
      end
      
      update :update do
        accept [:name, :description, :price, :rating, :stock_count, :category, :status, :deleted_at, :featured]
      end
    end
  end

  defmodule TestDomain do
    @moduledoc false
    use Ash.Domain,
      validate_config_inclusion?: false

    resources do
      resource Tapir.DataHelperFunctionalTest.Product
    end
  end

  setup do
    # Clear any existing data - ETS data layer automatically clears between tests
    # No need to manually clear for ETS

    # Create test products
    {:ok, product1} = Product
      |> Ash.Changeset.for_create(:create, %{
        name: "Laptop Pro",
        description: "High-performance laptop for professionals",
        price: Decimal.new("1299.99"),
        rating: 4.5,
        stock_count: 15,
        category: "electronics",
        status: "active",
        featured: true
      })
      |> Ash.create()

    {:ok, product2} = Product
      |> Ash.Changeset.for_create(:create, %{
        name: "Gaming Mouse",
        description: "Ergonomic gaming mouse with RGB lighting",
        price: Decimal.new("79.99"),
        rating: 4.2,
        stock_count: 0,
        category: "electronics", 
        status: "active",
        featured: false
      })
      |> Ash.create()

    {:ok, product3} = Product
      |> Ash.Changeset.for_create(:create, %{
        name: "Office Chair",
        description: "Comfortable office chair for long work sessions",
        price: Decimal.new("299.99"),
        rating: 3.8,
        stock_count: 5,
        category: "furniture",
        status: "discontinued",
        featured: false,
        deleted_at: DateTime.utc_now()
      })
      |> Ash.create()

    {:ok, product4} = Product
      |> Ash.Changeset.for_create(:create, %{
        name: "Wireless Headphones",
        description: "Premium noise-canceling headphones",
        price: Decimal.new("199.99"),
        rating: 4.7,
        stock_count: 25,
        category: "electronics",
        status: "active",
        featured: true
      })
      |> Ash.create()

    {:ok, product5} = Product
      |> Ash.Changeset.for_create(:create, %{
        name: "Standing Desk",
        description: nil, # Test nil description
        price: Decimal.new("449.99"),
        rating: 4.1,
        stock_count: 8,
        category: "furniture",
        status: "active",
        featured: false
      })
      |> Ash.create()

    # Test data is ready

    %{
      products: [product1, product2, product3, product4, product5],
      product1: product1,
      product2: product2,
      product3: product3,
      product4: product4,
      product5: product5
    }
  end

  describe "comparison operators with real data" do
    test "greater_than filters correctly", %{products: _products} do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{stock_count: %{greater_than: 10}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels, datasets: [%{data: data}]} = result
      # Should include: Laptop Pro (15), Wireless Headphones (25)
      assert length(labels) == 2
      assert "Laptop Pro" in labels
      assert "Wireless Headphones" in labels
      assert 15 in data
      assert 25 in data
    end

    test "greater_than_or_equal filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :rating,
        query_params: %{
          filter: %{rating: %{greater_than_or_equal: 4.5}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include: Laptop Pro (4.5), Wireless Headphones (4.7)
      assert length(labels) == 2
      assert "Laptop Pro" in labels
      assert "Wireless Headphones" in labels
    end

    test "less_than filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{stock_count: %{less_than: 10}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels, datasets: [%{data: data}]} = result
      # Should include: Gaming Mouse (0), Office Chair (5), Standing Desk (8)
      assert length(labels) == 3
      assert "Gaming Mouse" in labels
      assert "Office Chair" in labels  
      assert "Standing Desk" in labels
      assert 0 in data
      assert 5 in data
      assert 8 in data
    end

    test "not_equal filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{status: %{not_equal: "active"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should only include: Office Chair (discontinued)
      assert length(labels) == 1
      assert "Office Chair" in labels
    end
  end

  describe "string operations with real data" do
    test "starts_with filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{name: %{starts_with: "Laptop"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      assert length(labels) == 1
      assert "Laptop Pro" in labels
    end

    test "ends_with filters correctly (using contains as fallback for ETS)" do
      # For ETS, ends_with falls back to contains, so we test with "mouse" 
      # which is contained in "Gaming Mouse"
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{name: %{ends_with: "Mouse"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      assert length(labels) == 1
      assert "Gaming Mouse" in labels
    end

    test "contains filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{description: %{contains: "gaming"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      assert length(labels) == 1
      assert "Gaming Mouse" in labels
    end

    test "ilike filters correctly (case insensitive)" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{description: %{ilike: "%LAPTOP%"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      assert length(labels) == 1
      assert "Laptop Pro" in labels
    end
  end

  describe "null checks with real data" do
    test "is_nil true filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{description: %{is_nil: true}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include Standing Desk (nil description)
      assert length(labels) == 1
      assert "Standing Desk" in labels
    end

    test "is_nil false filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{deleted_at: %{is_nil: false}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include Office Chair (has deleted_at)
      assert length(labels) == 1
      assert "Office Chair" in labels
    end
  end

  describe "list operations with real data" do
    test "simple list (in) filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{category: ["electronics", "furniture"]}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include all products (all are either electronics or furniture)
      assert length(labels) == 5
    end

    test "explicit in filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{category: %{in: ["electronics"]}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include: Laptop Pro, Gaming Mouse, Wireless Headphones
      assert length(labels) == 3
      assert "Laptop Pro" in labels
      assert "Gaming Mouse" in labels
      assert "Wireless Headphones" in labels
    end

    test "not_in filters correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{status: %{not_in: ["discontinued"]}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should exclude Office Chair (discontinued)
      assert length(labels) == 4
      refute "Office Chair" in labels
    end
  end

  describe "complex mixed filters with real data" do
    test "multiple conditions are ANDed correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{
            category: "electronics",
            status: "active",
            stock_count: %{greater_than: 0},
            featured: true
          }
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include: Laptop Pro, Wireless Headphones (both electronics, active, in stock, featured)
      # Should exclude: Gaming Mouse (stock_count = 0)
      assert length(labels) == 2
      assert "Laptop Pro" in labels
      assert "Wireless Headphones" in labels
      refute "Gaming Mouse" in labels
    end

    test "list of filter maps works correctly" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: [
            %{status: "active"},
            %{category: "electronics"},
            %{stock_count: %{greater_than: 10}}
          ]
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include: Laptop Pro (15), Wireless Headphones (25)
      assert length(labels) == 2
      assert "Laptop Pro" in labels
      assert "Wireless Headphones" in labels
    end
  end

  describe "edge cases and error handling" do
    test "handles empty filter gracefully" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{filter: %{}}
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include all products
      assert length(labels) == 5
    end

    test "handles nil filter gracefully" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{filter: nil}
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include all products
      assert length(labels) == 5
    end

    test "unknown operators fallback to equality" do
      params = %{
        resource: Product,
        x_field: :name,
        y_field: :stock_count,
        query_params: %{
          filter: %{status: %{unknown_operator: "active"}}
        }
      }

      result = Tapir.DataHelper.process_data(params)

      assert %{labels: labels} = result
      # Should include all active products (treated as equality)
      assert length(labels) == 4
      refute "Office Chair" in labels
    end
  end
end