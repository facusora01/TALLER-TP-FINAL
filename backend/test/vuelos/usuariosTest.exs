defmodule Vuelos.UsuariosTest do
  use ExUnit.Case, async: false

  alias Vuelos.Usuarios

  setup do
    :dets.delete_all_objects(:usuarios)
    reiniciar_usuarios()
    :ok
  end

  test "registrar devuelve el usuario con id 1 cuando no hay nadie" do
    assert {:ok, %{id: 1, nombre: "Ana"}} = Usuarios.registrar("Ana")
  end

  test "cada usuario nuevo recibe un id distinto e incremental" do
    {:ok, ana} = Usuarios.registrar("Ana")
    {:ok, beto} = Usuarios.registrar("Beto")
    assert ana.id == 1
    assert beto.id == 2
  end

  test "obtener devuelve el usuario registrado, o :error si no existe" do
    {:ok, ana} = Usuarios.registrar("Ana")
    assert Usuarios.obtener(ana.id) == {:ok, ana}
    assert Usuarios.obtener(999) == :error
  end

  test "listar devuelve todos los usuarios registrados" do
    {:ok, ana} = Usuarios.registrar("Ana")
    {:ok, beto} = Usuarios.registrar("Beto")
    assert Enum.sort_by(Usuarios.listar(), & &1.id) == [ana, beto]
  end

  test "el estado se restaura desde DETS al reiniciar el proceso" do
    {:ok, ana} = Usuarios.registrar("Ana")
    {:ok, beto} = Usuarios.registrar("Beto")

    reiniciar_usuarios()

    assert Enum.sort_by(Usuarios.listar(), & &1.id) == [ana, beto]
    assert Usuarios.obtener(ana.id) == {:ok, ana}
  end

  test "tras reiniciar, el próximo id sigue desde el último persistido" do
    Usuarios.registrar("Ana")
    Usuarios.registrar("Beto")

    reiniciar_usuarios()

    assert {:ok, %{id: 3, nombre: "Caro"}} = Usuarios.registrar("Caro")
  end

  defp reiniciar_usuarios do
    #:ok = Supervisor.terminate_child(Vuelos.Supervisor, Vuelos.Usuarios)
    #{:ok, _pid} = Supervisor.restart_child(Vuelos.Supervisor, Vuelos.Usuarios)
    :ok = Supervisor.terminate_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)
    {:ok, _pid} = Supervisor.restart_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)
    :ok
  end
end
