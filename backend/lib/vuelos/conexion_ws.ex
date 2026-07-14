defmodule Vuelos.ConexionWS do
  @moduledoc """
  Proceso de conexión WebSocket (uno por cliente). Recibe los mensajes del
  cliente, los delega en `Vuelos.Protocolo` y reenvía los eventos push que
  otros procesos le manden como `{:enviar, texto}`.
  """

  @behaviour :cowboy_websocket

  @impl true
  def init(peticion, _estado) do
    estado = %{
      vuelo_id: nil
    }

    {:cowboy_websocket, peticion, estado, %{idle_timeout: 600_000}}
  end

  @impl true
  def websocket_init(estado) do
    {:ok, estado}
  end

  @impl true
  def websocket_handle({:text, texto}, estado) do
    {:reply, {:text, Vuelos.Protocolo.atender(texto, self())}, estado}
  end

  def websocket_handle(_cuadro, estado) do
    {:ok, estado}
  end

  @impl true
  def websocket_info({:enviar, texto}, estado) do
    {:reply, {:text, texto}, estado}
  end

  def websocket_info(_mensaje, estado) do
    {:ok, estado}
  end
end