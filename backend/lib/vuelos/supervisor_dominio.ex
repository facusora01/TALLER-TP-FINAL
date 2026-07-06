defmodule Vuelos.SupervisorDominio do
  use Supervisor

  def start_link(opciones \\ []) do
    Supervisor.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  @impl true
  def init(_opciones) do
    hijos = [
      Vuelos.Usuarios,
      {DynamicSupervisor, name: Vuelos.SupervisorVuelos, strategy: :one_for_one}
    ]

    Supervisor.init(hijos, strategy: :one_for_one)
  end
end