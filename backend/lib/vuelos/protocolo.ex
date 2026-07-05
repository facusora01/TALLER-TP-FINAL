defmodule Vuelos.Protocolo do
  @moduledoc """
  Protocolo de mensajes del WebSocket: decodifica el JSON del cliente,
  despacha según `type` y arma la respuesta (ver docs/NOTAS/M1/protocoloMensajes.md).
  """

  alias Vuelos.Usuarios

  @doc "Atiende un mensaje de texto del cliente y devuelve la respuesta ya codificada en JSON."
  def atender(texto) do
    case Jason.decode(texto) do
      {:ok, %{"type" => tipo} = mensaje} ->
        despachar(tipo, mensaje["request_id"], mensaje["payload"] || %{})

      _ ->
        error(nil, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
    end
  end

  defp despachar("registrar_usuario", request_id, %{"nombre" => nombre})
       when is_binary(nombre) do
    {:ok, usuario} = Usuarios.registrar(nombre)
    respuesta("registrar_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})
  end

  defp despachar("obtener_usuario", request_id, %{"usuario_id" => id}) do
    case Usuarios.obtener(id) do
      {:ok, usuario} ->
        respuesta("obtener_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})

      :error ->
        error(request_id, "USUARIO_NO_EXISTE", "No hay un usuario con ese id.")
    end
  end

  defp despachar(tipo, request_id, _payload) when is_binary(tipo) do
    error(request_id, "TIPO_DESCONOCIDO", "El servidor no reconoce el tipo de mensaje.")
  end

  defp despachar(_tipo, request_id, _payload) do
    error(request_id, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
  end

  defp respuesta(tipo, request_id, payload) do
    Jason.encode!(%{type: tipo, request_id: request_id, payload: payload})
  end

  defp error(request_id, codigo, mensaje) do
    respuesta("error", request_id, %{codigo: codigo, mensaje: mensaje})
  end
end
