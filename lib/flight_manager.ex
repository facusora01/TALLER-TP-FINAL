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

  def listar_vuelos do
    GenServer.call(__MODULE__, :listar_vuelos)
  end

  def handle_call(:listar_vuelos, _from, state) do
    {:reply, state, state}
  end

def buscar_vuelo(id_vuelo) do
  GenServer.call(__MODULE__, {:buscar_vuelo, id_vuelo})
end

def handle_call({:buscar_vuelo, id_vuelo}, _from, estado) do
  vuelo =
    Enum.find(estado, fn vuelo ->
      vuelo.id == id_vuelo
    end)

  {:reply, vuelo, estado}
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