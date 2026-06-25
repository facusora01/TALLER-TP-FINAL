defmodule Vuelos.AplicacionTest do
  use ExUnit.Case, async: false

  @procesos [
    Vuelos.Persistencia,
    Vuelos.Registro,
    Vuelos.Usuarios,
    Vuelos.SupervisorVuelos,
    Vuelos.SupervisorConexiones,
    Vuelos.SupervisorTareas
  ]

  test "el árbol de supervisión levanta todos los procesos esperados" do
    for nombre <- @procesos do
      assert Process.whereis(nombre) != nil, "falta el proceso #{inspect(nombre)}"
    end
  end

  test "los supervisores de vuelos y conexiones arrancan vacíos" do
    assert DynamicSupervisor.count_children(Vuelos.SupervisorVuelos).active == 0
    assert DynamicSupervisor.count_children(Vuelos.SupervisorConexiones).active == 0
  end
end
