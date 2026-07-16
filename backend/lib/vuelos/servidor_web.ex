defmodule Vuelos.ServidorWeb do
  @moduledoc "Levanta el listener HTTP de Cowboy y expone el WebSocket en /ws."

  @puerto_por_defecto 4000

  # PRE: recibe opciones (no se usan).
  # POST: devuelve la especificacion de hijo para el supervisor.
  def child_spec(_opciones) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  # PRE: el puerto configurado esta libre.
  # POST: arranca Cowboy escuchando ese puerto, con /ws atendido por ConexionWS.
  def start_link do
    rutas = [{:_, [{"/ws", Vuelos.ConexionWS, []}]}]
    despacho = :cowboy_router.compile(rutas)
    :cowboy.start_clear(__MODULE__, [port: puerto()], %{env: %{dispatch: despacho}})
  end

  # PRE: no recibe nada.
  # POST: devuelve el puerto configurado (4000 por defecto).
  def puerto do
    Application.get_env(:vuelos, :puerto_web, @puerto_por_defecto)
  end
end
