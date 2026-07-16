defmodule Vuelos.Aplicacion do
  use Application

  # PRE: la aplicacion no esta iniciada.
  # POST: levanta el arbol de supervision, carga los seeds y devuelve {:ok, pid}.
  @impl true
  def start(_tipo, _args) do
    hijos = [
      Vuelos.Persistencia,
      {Registry, keys: :unique, name: Vuelos.Registro},
      {Registry, keys: :duplicate, name: Vuelos.Suscriptores},
      Vuelos.SupervisorDominio,
      {DynamicSupervisor, name: Vuelos.SupervisorConexiones, strategy: :one_for_one},
      {Task.Supervisor, name: Vuelos.SupervisorTareas},
      Vuelos.ServidorWeb
    ]

    opciones = [strategy: :rest_for_one, name: Vuelos.Supervisor]
    Supervisor.start_link(hijos, opciones)
    |> tap(fn _ -> Vuelos.Seeds.cargar() end)
  end
end