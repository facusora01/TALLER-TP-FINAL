defmodule Vuelos.Persistencia do
  @moduledoc "Dueño de las tablas DETS; persiste el estado entre reinicios."

  use GenServer

  @tablas [:usuarios, :vuelos, :asientos, :reservas]
  @dir_datos "data"

  def start_link(opciones \\ []) do
    GenServer.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  def guardar(tabla, clave, valor) do
    :dets.insert(tabla, {clave, valor})
  end

  def obtener(tabla, clave) do
    case :dets.lookup(tabla, clave) do
      [{^clave, valor}] -> {:ok, valor}
      [] -> :error
    end
  end

  def todos(tabla) do
    :dets.foldl(fn registro, acc -> [registro | acc] end, [], tabla)
  end

  def borrar(tabla, clave) do
    :dets.delete(tabla, clave)
  end

  def sincronizar do
    Enum.each(@tablas, &:dets.sync/1)
  end

  @impl true
  def init(_opciones) do
    File.mkdir_p!(@dir_datos)
    Enum.each(@tablas, &abrir_tabla/1)
    {:ok, @tablas}
  end

  @impl true
  def terminate(_motivo, tablas) do
    Enum.each(tablas, &:dets.close/1)
    :ok
  end

  defp abrir_tabla(tabla) do
    archivo = @dir_datos |> Path.join("#{tabla}.dets") |> String.to_charlist()
    {:ok, ^tabla} = :dets.open_file(tabla, file: archivo, type: :set)
  end
end
