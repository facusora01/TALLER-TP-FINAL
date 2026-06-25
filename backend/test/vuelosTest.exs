defmodule VuelosTest do
  use ExUnit.Case

  test "saluda al mundo" do
    assert Vuelos.hola() == :mundo
  end
end
