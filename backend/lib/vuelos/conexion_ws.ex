defmodule Vuelos.ConexionWS do
  @moduledoc """
  Proceso de conexión WebSocket (uno por cliente). Recibe los mensajes del
  cliente, los delega en `Vuelos.Protocolo` y reenvía los eventos push que
  otros procesos le manden como `{:enviar, texto}`.
  """

  @behaviour :cowboy_websocket

  # PRE: recibe la peticion HTTP de upgrade a WebSocket.
  # POST: acepta el upgrade y define el estado inicial de la conexion.
  @impl true
  def init(peticion, _estado) do
    estado = %{
      vuelo_id: nil
    }

    {:cowboy_websocket, peticion, estado, %{idle_timeout: 600_000}}
  end

  # PRE: el upgrade a WebSocket ya se completo.
  # POST: deja el proceso de conexion listo para recibir mensajes.
  @impl true
  def websocket_init(estado) do
    {:ok, estado}
  end

  # PRE: recibe un frame de texto (JSON) del cliente.
  # POST: delega en Protocolo.atender y responde al cliente con el JSON que este armo.
  @impl true
  def websocket_handle({:text, texto}, estado) do
    {:reply, {:text, Vuelos.Protocolo.atender(texto, self())}, estado}
  end

  # PRE: recibe un frame que no es de texto (ping, binario, etc.).
  # POST: lo ignora; el estado no cambia.
  def websocket_handle(_cuadro, estado) do
    {:ok, estado}
  end

  # PRE: otro proceso (Broadcast) mando {:enviar, texto} a esta conexion.
  # POST: empuja el texto al cliente por el socket (push).
  @impl true
  def websocket_info({:enviar, texto}, estado) do
    {:reply, {:text, texto}, estado}
  end

  # PRE: recibe un mensaje interno no reconocido.
  # POST: lo ignora; el estado no cambia.
  def websocket_info(_mensaje, estado) do
    {:ok, estado}
  end
end