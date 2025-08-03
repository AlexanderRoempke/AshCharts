defmodule TapirTest do
  use ExUnit.Case
  doctest Tapir

  test "has version" do
    assert is_binary(Tapir.version())
  end
end
