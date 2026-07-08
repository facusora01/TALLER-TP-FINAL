defmodule TpFinal.FlightManager do
  use GenServer

  alias TpFinal.Flight

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    vuelos = [
      %Flight{
        id: 1,
        aerolinea: "Condor Air",
        origen: "Buenos Aires",
        destino: "Cordoba",
        fecha: "2026-07-15",
        precio: 50000,
        asientos: crear_asientos()
      },
      %Flight{
        id: 2,
        aerolinea: "Pampa Airlines",
        origen: "Buenos Aires",
        destino: "Mendoza",
        fecha: "2026-07-15",
        precio: 65000,
        asientos: crear_asientos()
      }
    ]

    {:ok, vuelos}
  end

  # ==========================
  # Funciones públicas
  # ==========================

  def listar_vuelos do
    GenServer.call(__MODULE__, :listar_vuelos)
  end

  def buscar_vuelo(id_vuelo) do
    GenServer.call(__MODULE__, {:buscar_vuelo, id_vuelo})
  end

  def buscar_por_destino(destino) do
    GenServer.call(
      __MODULE__,
      {:buscar_por_destino, destino}
    )
  end

  def buscar_por_fecha(fecha) do
    GenServer.call(
      __MODULE__,
      {:buscar_por_fecha, fecha}
    )
  end

  def obtener_asientos(id_vuelo) do
    GenServer.call(
      __MODULE__,
      {:obtener_asientos, id_vuelo}
    )
  end

  # ==========================
  # Handle calls
  # ==========================

  def handle_call(:listar_vuelos, _from, estado) do
    {:reply, estado, estado}
  end

  def handle_call({:buscar_vuelo, id_vuelo}, _from, estado) do
    vuelo =
      Enum.find(estado, fn vuelo ->
        vuelo.id == id_vuelo
      end)

    {:reply, vuelo, estado}
  end

  def handle_call(
        {:buscar_por_destino, destino},
        _from,
        estado
      ) do
    vuelos =
      Enum.filter(estado, fn vuelo ->
        vuelo.destino == destino
      end)

    {:reply, vuelos, estado}
  end

  def handle_call(
        {:buscar_por_fecha, fecha},
        _from,
        estado
      ) do
    vuelos =
      Enum.filter(estado, fn vuelo ->
        vuelo.fecha == fecha
      end)

    {:reply, vuelos, estado}
  end

  def handle_call(
        {:obtener_asientos, id_vuelo},
        _from,
        estado
      ) do
    vuelo =
      Enum.find(estado, fn vuelo ->
        vuelo.id == id_vuelo
      end)

    if vuelo do
      {:reply, vuelo.asientos, estado}
    else
      {:reply, nil, estado}
    end
  end

  defp crear_asientos do
    Enum.map(1..20, fn numero ->
      %{
        numero: numero,
        estado: :libre
      }
    end)
  end
end