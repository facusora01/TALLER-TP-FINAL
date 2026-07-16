defmodule Vuelos.Protocolo do
  @moduledoc """
  Protocolo de mensajes del WebSocket: decodifica el JSON del cliente,
  despacha según `type` y arma la respuesta (ver docs/NOTAS/M1/protocoloMensajes.md).
  """

  alias Vuelos.{Usuarios, GestorVuelos}

  @doc "Atiende un mensaje de texto del cliente y devuelve la respuesta ya codificada en JSON."
  # PRE: recibe el texto que llego por el WebSocket y el pid de la conexion.
  # POST: decodifica, despacha segun type y devuelve la respuesta ya codificada en JSON (o un error si el mensaje no era valido).
  def atender(texto, pid \\ self()) do
    case Jason.decode(texto) do
      {:ok, %{"type" => tipo} = mensaje} ->
        despachar(tipo, mensaje["request_id"], mensaje["payload"] || %{}, pid)

      _ ->
        error(nil, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
    end
  end

  # PRE: el payload trae nombre (string).
  # POST: crea el usuario y responde "registrar_usuario_ok" con id y nombre.
  defp despachar("registrar_usuario", request_id, %{"nombre" => nombre}, _pid)
       when is_binary(nombre) do
    {:ok, usuario} = Usuarios.registrar(nombre)
    respuesta("registrar_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})
  end

  # PRE: el payload trae nombre (string).
  # POST: responde "iniciar_sesion_ok" con el usuario existente o recien creado.
  defp despachar("iniciar_sesion", request_id, %{"nombre" => nombre}, _pid)
       when is_binary(nombre) do
    {:ok, usuario} = Usuarios.iniciar_sesion(nombre)
    respuesta("iniciar_sesion_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})
  end

  # PRE: el payload trae usuario_id.
  # POST: responde "obtener_usuario_ok" con el usuario, o error USUARIO_NO_EXISTE.
  defp despachar("obtener_usuario", request_id, %{"usuario_id" => id}, _pid) do
    case Usuarios.obtener(id) do
      {:ok, usuario} ->
        respuesta("obtener_usuario_ok", request_id, %{usuario_id: usuario.id, nombre: usuario.nombre})

      :error ->
        error(request_id, "USUARIO_NO_EXISTE", "No hay un usuario con ese id.")
    end
  end

  # PRE: no necesita payload.
  # POST: responde "listar_vuelos_ok" con el resumen de todos los vuelos.
  defp despachar("listar_vuelos", request_id, _payload, _pid) do
    vuelos =
      GestorVuelos.listar_vuelos()
      |> Enum.map(&resumen_vuelo/1)

    respuesta(
      "listar_vuelos_ok",
      request_id,
      %{vuelos: vuelos}
    )
  end

  # PRE: no necesita payload.
  # POST: responde "listar_aerolineas_ok" con la lista de aerolineas.
  defp despachar("listar_aerolineas", request_id, _payload, _pid) do
    respuesta(
      "listar_aerolineas_ok",
      request_id,
      %{aerolineas: GestorVuelos.listar_aerolineas()}
    )
  end

  # PRE: el payload trae usuario_id.
  # POST: responde "mis_reservas_ok" con las reservas del usuario, o error USUARIO_NO_EXISTE.
  defp despachar("mis_reservas", request_id, %{"usuario_id" => usuario_id}, _pid) do
    case Usuarios.obtener(usuario_id) do
      :error ->
        error(
          request_id,
          "USUARIO_NO_EXISTE",
          "No existe un usuario con ese id."
        )

      {:ok, _usuario} ->
        respuesta(
          "mis_reservas_ok",
          request_id,
          %{reservas: GestorVuelos.reservas_de_usuario(usuario_id)}
        )
    end
  end

  # PRE: el payload trae vuelo_id.
  # POST: responde "buscar_vuelo_ok" con el resumen del vuelo, o error VUELO_NO_EXISTE.
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
          resumen_vuelo(vuelo)
        )
    end
  end

  # PRE: el payload trae vuelo_id.
  # POST: responde "obtener_asientos_ok" con los asientos del vuelo, o error VUELO_NO_EXISTE.
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

  # PRE: el payload trae vuelo_id, numero_asiento y usuario_id.
  # POST: crea la reserva y responde "reservar_asiento_ok" con su id, o el error correspondiente.
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

  # PRE: el payload trae vuelo_id y reserva_id.
  # POST: inicia el pago y responde "confirmar_reserva_ok", o el error correspondiente.
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

  # PRE: el payload trae vuelo_id y reserva_id.
  # POST: cancela la reserva y responde "cancelar_reserva_ok", o el error correspondiente.
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

  # PRE: el payload trae vuelo_id y reserva_id.
  # POST: expira la reserva y responde "expirar_reserva_ok", o el error correspondiente.
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

  # PRE: el payload trae vuelo_id; pid es la conexion WebSocket del cliente.
  # POST: suscribe la conexion a los push de ese vuelo y responde "suscribir_vuelo_ok".
  defp despachar("suscribir_vuelo", request_id, %{"vuelo_id" => vuelo_id}, pid) do
    Vuelos.Broadcast.subscribir(vuelo_id, pid)

    respuesta(
      "suscribir_vuelo_ok",
      request_id,
      %{}
    )
  end

  # PRE: ninguna clausula anterior matcheo (tipo desconocido o payload incompleto).
  # POST: responde error TIPO_DESCONOCIDO.
  defp despachar(tipo, request_id, _payload, _pid) when is_binary(tipo) do
    error(request_id, "TIPO_DESCONOCIDO", "El servidor no reconoce el tipo de mensaje.")
  end

  # PRE: el campo type ni siquiera es un string.
  # POST: responde error MENSAJE_INVALIDO.
  defp despachar(_tipo, request_id, _payload, _pid) do
    error(request_id, "MENSAJE_INVALIDO", "El mensaje no respeta el formato del protocolo.")
  end

  # PRE: recibe un Vuelo con asientos.
  # POST: devuelve un mapa con los campos publicos del vuelo (sin reservas ni timers).
  defp resumen_vuelo(vuelo) do
    %{
      id: vuelo.id,
      aerolinea_id: vuelo.aerolinea_id,
      origen: vuelo.origen,
      destino: vuelo.destino,
      fecha: vuelo.fecha,
      hora: vuelo.hora,
      precio: vuelo.precio,
      # Map.get: los vuelos persistidos antes de TAL-32 no tienen estos campos.
      avion: Map.get(vuelo, :avion),
      distribucion: Map.get(vuelo, :distribucion, [3, 3]),
      asientos_totales: vuelo.asientos_totales,
      asientos_disponibles: Enum.count(vuelo.asientos, &(&1.estado == :libre))
    }
  end

  # PRE: recibe tipo, request_id y un payload codificable a JSON.
  # POST: devuelve el JSON con {type, request_id, payload}.
  defp respuesta(tipo, request_id, payload) do
    Jason.encode!(%{type: tipo, request_id: request_id, payload: payload})
  end

  # PRE: recibe request_id, codigo y mensaje.
  # POST: devuelve el JSON de tipo "error" con codigo y mensaje.
  defp error(request_id, codigo, mensaje) do
    respuesta("error", request_id, %{codigo: codigo, mensaje: mensaje})
  end
end
