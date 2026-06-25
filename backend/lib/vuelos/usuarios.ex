defmodule Vuelos.Usuarios do
  @moduledoc "GenServer de usuarios: registro y lookup, persistido en DETS."

  use GenServer

  alias Vuelos.Persistencia

  @tabla :usuarios

  def start_link(opciones \\ []) do
    GenServer.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  def registrar(nombre) do
    GenServer.call(__MODULE__, {:registrar, nombre})
  end

  def obtener(id) do
    GenServer.call(__MODULE__, {:obtener, id})
  end

  def listar do
    GenServer.call(__MODULE__, :listar)
  end

  @impl true
  def init(_opciones) do
    {:ok, hidratar()}
  end

  @impl true
  def handle_call({:registrar, nombre}, _origen, usuarios) do
    id = siguiente_id(usuarios)
    usuario = %{id: id, nombre: nombre}
    Persistencia.guardar(@tabla, id, usuario)
    {:reply, {:ok, usuario}, Map.put(usuarios, id, usuario)}
  end

  def handle_call({:obtener, id}, _origen, usuarios) do
    {:reply, Map.fetch(usuarios, id), usuarios}
  end

  def handle_call(:listar, _origen, usuarios) do
    {:reply, Map.values(usuarios), usuarios}
  end

  defp hidratar do
    @tabla
    |> Persistencia.todos()
    |> Map.new()
  end

  defp siguiente_id(usuarios) when map_size(usuarios) == 0, do: 1
  defp siguiente_id(usuarios), do: (usuarios |> Map.keys() |> Enum.max()) + 1
end
