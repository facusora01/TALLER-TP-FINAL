defmodule Vuelos.Usuarios do
  @moduledoc "GenServer de usuarios: registro y lookup, persistido en DETS."

  use GenServer

  alias Vuelos.Persistencia

  @tabla :usuarios

  # PRE: recibe opciones (no se usan); Persistencia ya iniciada.
  # POST: arranca el proceso con los usuarios cargados en memoria desde DETS; devuelve {:ok, pid}.
  def start_link(opciones \\ []) do
    GenServer.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  # PRE: recibe el nombre (string) del usuario.
  # POST: crea un usuario nuevo, lo persiste y devuelve {:ok, usuario}.
  def registrar(nombre) do
    GenServer.call(__MODULE__, {:registrar, nombre})
  end

  @doc "Devuelve el usuario con ese nombre si ya existe, o lo crea. Permite \"volver a entrar\"."
  # PRE: recibe el nombre (string) del usuario.
  # POST: devuelve {:ok, usuario} con el existente de ese nombre, o lo crea si no existe.
  def iniciar_sesion(nombre) do
    GenServer.call(__MODULE__, {:iniciar_sesion, nombre})
  end

  # PRE: recibe el id del usuario.
  # POST: devuelve {:ok, usuario} si existe ese id, :error si no. No modifica nada.
  def obtener(id) do
    GenServer.call(__MODULE__, {:obtener, id})
  end

  # PRE: no recibe nada.
  # POST: devuelve la lista de todos los usuarios. No modifica nada.
  def listar do
    GenServer.call(__MODULE__, :listar)
  end

  # PRE: las tablas DETS estan abiertas.
  # POST: deja como estado inicial el mapa id => usuario leido de disco.
  @impl true
  def init(_opciones) do
    {:ok, hidratar()}
  end

  # PRE: llega el call {:registrar, nombre}.
  # POST: crea el usuario, lo agrega al estado, lo persiste y responde {:ok, usuario}.
  @impl true
  def handle_call({:registrar, nombre}, _origen, usuarios) do
    {usuario, usuarios} = crear(nombre, usuarios)
    {:reply, {:ok, usuario}, usuarios}
  end

  # PRE: llega el call {:iniciar_sesion, nombre}.
  # POST: responde {:ok, usuario} con el existente de ese nombre, o crea uno nuevo.
  def handle_call({:iniciar_sesion, nombre}, _origen, usuarios) do
    case Enum.find(usuarios, fn {_id, u} -> u.nombre == nombre end) do
      {_id, usuario} ->
        {:reply, {:ok, usuario}, usuarios}

      nil ->
        {usuario, usuarios} = crear(nombre, usuarios)
        {:reply, {:ok, usuario}, usuarios}
    end
  end

  # PRE: llega el call {:obtener, id}.
  # POST: responde {:ok, usuario} o :error; el estado no cambia.
  def handle_call({:obtener, id}, _origen, usuarios) do
    {:reply, Map.fetch(usuarios, id), usuarios}
  end

  # PRE: llega el call :listar.
  # POST: responde la lista de usuarios; el estado no cambia.
  def handle_call(:listar, _origen, usuarios) do
    {:reply, Map.values(usuarios), usuarios}
  end

  # PRE: recibe el nombre y el mapa actual de usuarios.
  # POST: crea el usuario con id nuevo, lo guarda en DETS y devuelve {usuario, mapa actualizado}.
  defp crear(nombre, usuarios) do
    id = siguiente_id(usuarios)
    usuario = %{id: id, nombre: nombre}
    Persistencia.guardar(@tabla, id, usuario)
    {usuario, Map.put(usuarios, id, usuario)}
  end

  # PRE: la tabla :usuarios esta abierta.
  # POST: devuelve el mapa id => usuario leido de disco.
  defp hidratar do
    @tabla
    |> Persistencia.todos()
    |> Map.new()
  end

  # PRE: recibe el mapa id => usuario.
  # POST: devuelve un id mayor a todos los existentes (1 si esta vacio).
  defp siguiente_id(usuarios) when map_size(usuarios) == 0, do: 1
  defp siguiente_id(usuarios), do: (usuarios |> Map.keys() |> Enum.max()) + 1
end
