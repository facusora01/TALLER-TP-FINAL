defmodule Vuelos.Protocolo do
  @moduledoc """
  Protocolo de mensajes del WebSocket: decodifica el JSON del cliente,
  despacha según `type` y arma la respuesta (ver docs/NOTAS/M1/protocoloMensajes.md).
  """

  alias Vuelos.{Usuarios, GestorVuelos}

  @doc "Atiende un mensaje de texto del cliente y devuelve la respuesta ya codificada en JSON."
  def atender(texto, pid \\ self()) do
    case Jason.decode(texto) do
      {:ok, %{"type" => tipo} = mensaje} ->
        despachar(tipo, mensaje["request_id"], mensaje["payload"] || %{}, pid)

      _ ->
        error(nil, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
    end
  end

  defp despachar("registrar_usuario", request_id, %{"nombre" => nombre}, _pid)
       when is_binary(nombre) do
    {:ok, usuario} = Usuarios.registrar(nombre)
    respuesta("registrar_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})
  end

  defp despachar("obtener_usuario", request_id, %{"usuario_id" => id}, _pid) do
    case Usuarios.obtener(id) do
      {:ok, usuario} ->
        respuesta("obtener_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})

      :error ->
        error(request_id, "USUARIO_NO_EXISTE", "No hay un usuario con ese id.")
    end
  end

  defp despachar("listar_vuelos", request_id, _payload, _pid) do
    vuelos =
      GestorVuelos.listar_vuelos()
      |> Enum.map(fn vuelo ->
        %{
          id: vuelo.id,
          aerolinea_id: vuelo.aerolinea_id,
          origen: vuelo.origen,
          destino: vuelo.destino,
          fecha: vuelo.fecha,
          hora: vuelo.hora,
          precio: vuelo.precio,
          asientos_totales: vuelo.asientos_totales
        }
      end)

    respuesta(
      "listar_vuelos_ok",
      request_id,
      %{vuelos: vuelos}
    )
  end

  defp despachar("buscar_vuelo", request_id, %{"vuelo_id" => id}, _pid) do
    case GestorVuelos.buscar_vuelo(id) do
      nil ->
        error(
          request_id,
          "VUELO_NO_EXISTE",
          "No existe un vuelo con ese id."
        )

      vuelo ->
        respuesta(
          "buscar_vuelo_ok",
          request_id,
          %{
            id: vuelo.id,
            aerolinea_id: vuelo.aerolinea_id,
            origen: vuelo.origen,
            destino: vuelo.destino,
            fecha: vuelo.fecha,
            hora: vuelo.hora,
            precio: vuelo.precio,
            asientos_totales: vuelo.asientos_totales
          }
        )
    end
  end

  defp despachar("obtener_asientos", request_id, %{"vuelo_id" => id}, _pid) do
    case GestorVuelos.obtener_asientos(id) do
      {:ok, asientos} ->
        respuesta(
          "obtener_asientos_ok",
          request_id,
          %{asientos: asientos}
        )

      :error ->
        error(
          request_id,
          "VUELO_NO_EXISTE",
          "No existe un vuelo con ese id."
        )
    end
  end

  defp despachar("reservar_asiento", request_id, %{"vuelo_id" => vuelo_id, "numero_asiento" => numero_asiento, "usuario_id" => usuario_id}, _pid) do
    case Usuarios.obtener(usuario_id) do
      :error ->
        error(
          request_id,
          "USUARIO_NO_EXISTE",
          "No existe un usuario con ese id."
        )

      {:ok, usuario} ->
        case GestorVuelos.reservar_asiento(
              vuelo_id,
              numero_asiento,
              usuario
            ) do
          {:ok, id_reserva} ->
            respuesta(
              "reservar_asiento_ok",
              request_id,
              %{
                reserva_id: id_reserva
              }
            )

          :ocupado ->
            error(
              request_id,
              "ASIENTO_OCUPADO",
              "El asiento ya se encuentra reservado."
            )

          :asiento_no_existe ->
            error(
              request_id,
              "ASIENTO_NO_EXISTE",
              "No existe ese asiento."
            )

          :error ->
            error(
              request_id,
              "VUELO_NO_EXISTE",
              "No existe un vuelo con ese id."
            )
        end
    end
  end

  defp despachar("confirmar_reserva", request_id, %{ "vuelo_id" => vuelo_id, "reserva_id" => reserva_id}, _pid) do
    case GestorVuelos.confirmar_reserva(vuelo_id, reserva_id) do
      :ok ->
        respuesta(
          "confirmar_reserva_ok",
          request_id,
          %{}
        )

      :no_existe ->
        error(
          request_id,
          "RESERVA_NO_EXISTE",
          "No existe la reserva indicada."
        )

      :estado_invalido ->
        error(
          request_id,
          "ESTADO_INVALIDO",
          "La reserva no puede confirmarse."
        )

      :error ->
        error(
          request_id,
          "VUELO_NO_EXISTE",
          "No existe un vuelo con ese id."
        )
    end
  end

  defp despachar("cancelar_reserva", request_id, %{ "vuelo_id" => vuelo_id, "reserva_id" => reserva_id}, _pid) do
    case GestorVuelos.cancelar_reserva(vuelo_id, reserva_id) do
      :ok ->
        respuesta(
          "cancelar_reserva_ok",
          request_id,
          %{}
        )

      :no_existe ->
        error(
          request_id,
          "RESERVA_NO_EXISTE",
          "No existe la reserva indicada."
        )

      :estado_invalido ->
        error(
          request_id,
          "ESTADO_INVALIDO",
          "La reserva no puede cancelarse."
        )

      :error ->
        error(
          request_id,
          "VUELO_NO_EXISTE",
          "No existe un vuelo con ese id."
        )
    end
  end

  defp despachar("expirar_reserva", request_id, %{"vuelo_id" => vuelo_id, "reserva_id" => reserva_id}, _pid) do
    case GestorVuelos.expirar_reserva(vuelo_id, reserva_id) do
      :ok ->
        respuesta(
          "expirar_reserva_ok",
          request_id,
          %{}
        )

      :no_existe ->
        error(
          request_id,
          "RESERVA_NO_EXISTE",
          "No existe la reserva indicada."
        )

      :estado_invalido ->
        error(
          request_id,
          "ESTADO_INVALIDO",
          "La reserva no puede expirar."
        )

      :error ->
        error(
          request_id,
          "VUELO_NO_EXISTE",
          "No existe un vuelo con ese id."
        )
    end
  end

  defp despachar("suscribir_vuelo", request_id, %{"vuelo_id" => vuelo_id}, pid) do
    Vuelos.Broadcast.subscribir(vuelo_id, pid)

    respuesta(
      "suscribir_vuelo_ok",
      request_id,
      %{}
    )
  end

  defp despachar(tipo, request_id, _payload, _pid) when is_binary(tipo) do
    error(request_id, "TIPO_DESCONOCIDO", "El servidor no reconoce el tipo de mensaje.")
  end

  defp despachar(_tipo, request_id, _payload, _pid) do
    error(request_id, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
  end

  defp respuesta(tipo, request_id, payload) do
    Jason.encode!(%{type: tipo, request_id: request_id, payload: payload})
  end

  defp error(request_id, codigo, mensaje) do
    respuesta("error", request_id, %{codigo: codigo, mensaje: mensaje})
  end
end
