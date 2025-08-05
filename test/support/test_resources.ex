defmodule Tapir.Test.Support.TestResources do
  @moduledoc """
  Test resources for functional testing of DataHelper filtering.
  """

  defmodule Product do
    @moduledoc false
    use Ash.Resource,
      domain: Tapir.Test.Support.TestDomain,
      data_layer: Ash.DataLayer.Ets

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
      defaults [:read, :destroy, create: :*, update: :*]
    end

    aggregates do
      count :review_count, :reviews
      avg :average_rating, :reviews, :rating
    end

    relationships do
      has_many :reviews, Tapir.Test.Support.TestResources.Review
    end
  end

  defmodule Review do
    @moduledoc false
    use Ash.Resource,
      domain: Tapir.Test.Support.TestDomain,
      data_layer: Ash.DataLayer.Ets

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id
      attribute :rating, :integer, constraints: [min: 1, max: 5]
      attribute :comment, :string
      attribute :reviewer_name, :string
      attribute :created_at, :utc_datetime_usec, default: &DateTime.utc_now/0
    end

    relationships do
      belongs_to :product, Tapir.Test.Support.TestResources.Product
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end
  end

  defmodule TestDomain do
    @moduledoc false
    use Ash.Domain,
      validate_config_inclusion?: false

    resources do
      resource Product
      resource Review
    end
  end
end