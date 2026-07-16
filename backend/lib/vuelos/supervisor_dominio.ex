defmodule Vuelos.SupervisorDominio do
  use Supervisor

  # PRE: recibe opciones (no se usan); Persistencia ya iniciada.
  # POST: arranca el supervisor del dominio; devuelve {:ok, pid}.
  def start_link(opciones \\ []) do
    Supervisor.start_link(__MODULE__, opciones, name: __MODULE__)
  end

  # PRE: invocado por Supervisor.start_link al arrancar.
  # POST: define los hijos del dominio con estrategia :one_for_one.
  @impl true
  def init(_opciones) do
    hijos = [
      Vuelos.Usuarios,

      {
        Registry,
        keys: :duplicate,
        name: Vuelos.BroadcastRegistry
      },

      {
        DynamicSupervisor,
        name: Vuelos.SupervisorVuelos,
        strategy: :one_for_one
      }
    ]

    Supervisor.init(hijos, strategy: :one_for_one)
  end
end