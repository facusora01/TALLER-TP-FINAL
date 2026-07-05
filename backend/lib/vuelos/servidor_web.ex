defmodule Vuelos.ServidorWeb do
  @moduledoc "Levanta el listener HTTP de Cowboy y expone el WebSocket en /ws."

  @puerto_por_defecto 4000

  def child_spec(_opciones) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}}
  end

  def start_link do
    rutas = [{:_, [{"/ws", Vuelos.ConexionWS, []}]}]
    despacho = :cowboy_router.compile(rutas)
    :cowboy.start_clear(__MODULE__, [port: puerto()], %{env: %{dispatch: despacho}})
  end

  def puerto do
    Application.get_env(:vuelos, :puerto_web, @puerto_por_defecto)
  end
end
