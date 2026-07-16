defmodule Vuelos.Persistencia do
  @moduledoc "Dueño de las tablas DETS; persiste el estado entre reinicios."

  use GenServer

  @tablas [:usuarios, :vuelos, :asientos, :reservas]
  @dir_datos "data"

  # PRE: recibe opciones (no se usan); el directorio "data" es accesible.
  # POST: arranca el proceso con las tablas DETS abiertas; devuelve {:ok, pid}.
  def start_link(opciones \\ []) do
    GenServer.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  # PRE: recibe tabla, clave y valor; la tabla esta abierta.
  # POST: inserta {clave, valor} en disco (sobrescribe si existia).
  def guardar(tabla, clave, valor) do
    :dets.insert(tabla, {clave, valor})
  end

  # PRE: recibe tabla y clave; la tabla esta abierta.
  # POST: devuelve {:ok, valor} si la clave existe, :error si no. No modifica nada.
  def obtener(tabla, clave) do
    case :dets.lookup(tabla, clave) do
      [{^clave, valor}] -> {:ok, valor}
      [] -> :error
    end
  end

  # PRE: recibe la tabla; esta abierta.
  # POST: devuelve la lista con todos los {clave, valor} de la tabla. No modifica nada.
  def todos(tabla) do
    :dets.foldl(fn registro, acc -> [registro | acc] end, [], tabla)
  end

  # PRE: recibe tabla y clave; la tabla esta abierta.
  # POST: borra la clave de la tabla en disco.
  def borrar(tabla, clave) do
    :dets.delete(tabla, clave)
  end

  # PRE: las tablas estan abiertas.
  # POST: vuelca a disco todo lo pendiente de las 4 tablas.
  def sincronizar do
    Enum.each(@tablas, &:dets.sync/1)
  end

  # PRE: invocado por GenServer.start_link al arrancar.
  # POST: crea el directorio "data" y abre las 4 tablas DETS; el estado es la lista de tablas.
  @impl true
  def init(_opciones) do
    File.mkdir_p!(@dir_datos)
    Enum.each(@tablas, &abrir_tabla/1)
    {:ok, @tablas}
  end

  # PRE: el proceso esta terminando; recibe el motivo y la lista de tablas.
  # POST: cierra todas las tablas DETS.
  @impl true
  def terminate(_motivo, tablas) do
    Enum.each(tablas, &:dets.close/1)
    :ok
  end

  # PRE: recibe el nombre de la tabla; el directorio "data" existe.
  # POST: abre la tabla DETS apuntando a data/<tabla>.dets.
  defp abrir_tabla(tabla) do
    archivo = @dir_datos |> Path.join("#{tabla}.dets") |> String.to_charlist()
    {:ok, ^tabla} = :dets.open_file(tabla, file: archivo, type: :set)
  end
end
