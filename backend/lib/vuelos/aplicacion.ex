defmodule Vuelos.Aplicacion do

  use Application

  @impl true
  def start(_tipo, _args) do
    hijos = [
      Vuelos.Persistencia,
      {Registry, keys: :unique, name: Vuelos.Registro},
      Vuelos.Usuarios,
      {DynamicSupervisor, name: Vuelos.SupervisorVuelos, strategy: :one_for_one},
      {DynamicSupervisor, name: Vuelos.SupervisorConexiones, strategy: :one_for_one},
      {Task.Supervisor, name: Vuelos.SupervisorTareas}
    ]

    opciones = [strategy: :rest_for_one, name: Vuelos.Supervisor]
    Supervisor.start_link(hijos, opciones)
  end
end
