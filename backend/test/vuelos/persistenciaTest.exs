defmodule Vuelos.PersistenciaTest do
  use ExUnit.Case, async: false

  alias Vuelos.Persistencia

  setup do
    :dets.delete_all_objects(:usuarios)
    :ok
  end

  test "obtener devuelve :error si la clave no existe" do
    assert Persistencia.obtener(:usuarios, 1) == :error
  end

  test "guardar persiste y obtener recupera el valor" do
    Persistencia.guardar(:usuarios, 1, %{id: 1, nombre: "Ana"})
    assert Persistencia.obtener(:usuarios, 1) == {:ok, %{id: 1, nombre: "Ana"}}
  end

  test "guardar sobre una clave existente pisa el valor anterior" do
    Persistencia.guardar(:usuarios, 1, %{id: 1, nombre: "Ana"})
    Persistencia.guardar(:usuarios, 1, %{id: 1, nombre: "Ana María"})
    assert Persistencia.obtener(:usuarios, 1) == {:ok, %{id: 1, nombre: "Ana María"}}
  end

  test "todos devuelve todos los registros guardados" do
    Persistencia.guardar(:usuarios, 1, %{id: 1, nombre: "Ana"})
    Persistencia.guardar(:usuarios, 2, %{id: 2, nombre: "Beto"})

    registros = Enum.sort(Persistencia.todos(:usuarios))
    assert registros == [{1, %{id: 1, nombre: "Ana"}}, {2, %{id: 2, nombre: "Beto"}}]
  end

  test "borrar elimina solo la clave indicada" do
    Persistencia.guardar(:usuarios, 1, %{id: 1, nombre: "Ana"})
    Persistencia.guardar(:usuarios, 2, %{id: 2, nombre: "Beto"})

    Persistencia.borrar(:usuarios, 1)

    assert Persistencia.obtener(:usuarios, 1) == :error
    assert Persistencia.obtener(:usuarios, 2) == {:ok, %{id: 2, nombre: "Beto"}}
  end
end
