defmodule Vuelos.GestorVuelos do
  @moduledoc """
  API para acceder a los vuelos del sistema.

  Los ServidorVuelo se crean bajo demanda.
  """

  alias Vuelos.{Persistencia, ServidorVuelo}

  @tabla :vuelos

  # PRE: la tabla :vuelos esta abierta.
  # POST: devuelve la lista de todos los vuelos. No modifica nada.
  def listar_vuelos do
    Persistencia.todos(@tabla)
    |> Enum.flat_map(fn
      {{:vuelo, _}, vuelo} -> [vuelo]
      _ -> []
    end)
  end

  # PRE: recibe el id del vuelo; la tabla :vuelos esta abierta.
  # POST: devuelve el vuelo con ese id, o nil si no existe.
  def buscar_vuelo(id) do
    case Persistencia.obtener(@tabla, {:vuelo, id}) do
      {:ok, vuelo} -> vuelo
      :error -> nil
    end
  end

  # PRE: la tabla :vuelos esta abierta.
  # POST: devuelve la lista de todas las aerolineas. No modifica nada.
  def listar_aerolineas do
    Persistencia.todos(@tabla)
    |> Enum.flat_map(fn
      {{:aerolinea, _}, aerolinea} -> [aerolinea]
      _ -> []
    end)
  end

  # PRE: recibe el id de un usuario existente.
  # POST: devuelve sus reservas en todos los vuelos, con segundos restantes si estan pendientes.
  def reservas_de_usuario(usuario_id) do
    listar_vuelos()
    |> Enum.flat_map(fn vuelo ->
      vuelo.reservas
      |> Map.values()
      |> Enum.filter(fn reserva -> reserva.usuario.id == usuario_id end)
      |> Enum.map(fn reserva ->
        asiento =
          Enum.find(vuelo.asientos, &(&1.numero == reserva.numero_asiento))

        %{
          reserva_id: reserva.id,
          vuelo_id: vuelo.id,
          aerolinea_id: vuelo.aerolinea_id,
          origen: vuelo.origen,
          destino: vuelo.destino,
          fecha: vuelo.fecha,
          hora: vuelo.hora,
          numero_asiento: reserva.numero_asiento,
          estado: reserva.estado,
          segundos_restantes:
            if reserva.estado == :pendiente do
              max(
                60 -
                DateTime.diff(
                  DateTime.utc_now(),
                  reserva.creada_en,
                  :second
                ),
                0
              )
            else
              0
            end,
          clase: asiento[:clase],
        }
      end)
    end)
  end

  # PRE: recibe el destino; la tabla :vuelos esta abierta.
  # POST: devuelve los vuelos con ese destino exacto. No modifica nada.
  def buscar_por_destino(destino) do
    listar_vuelos()
    |> Enum.filter(fn vuelo ->
      vuelo.destino == destino
    end)
  end

  # PRE: recibe la fecha; la tabla :vuelos esta abierta.
  # POST: devuelve los vuelos con esa fecha exacta. No modifica nada.
  def buscar_por_fecha(fecha) do
    listar_vuelos()
    |> Enum.filter(fn vuelo ->
      vuelo.fecha == fecha
    end)
  end

  # PRE: recibe el id del vuelo.
  # POST: levanta el servidor si hace falta y devuelve {:ok, vuelo completo}, o :error si el vuelo no existe.
  def obtener_estado(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_estado(id)}
    end
  end

  # PRE: recibe el id del vuelo.
  # POST: devuelve {:ok, asientos del vuelo}, o :error si el vuelo no existe.
  def obtener_asientos(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_asientos(id)}
    end
  end

  # PRE: recibe el id del vuelo.
  # POST: devuelve {:ok, reservas del vuelo}, o :error si el vuelo no existe.
  def obtener_reservas(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_reservas(id)}
    end
  end

  # PRE: recibe id del vuelo, numero de asiento y el usuario (ya validado).
  # POST: reserva el asiento y devuelve {:ok, reserva_id} si estaba libre; :ocupado, :asiento_no_existe o :error si no.
  def reservar_asiento(id, numero_asiento, usuario) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.reservar_asiento(id, numero_asiento, usuario)
    end
  end

  # PRE: recibe id del vuelo e id de la reserva.
  # POST: inicia el pago si la reserva estaba pendiente; :no_existe / :estado_invalido / :error si no.
  def confirmar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.confirmar_reserva(id, id_reserva)
    end
  end

  # PRE: recibe id del vuelo e id de la reserva.
  # POST: cancela la reserva y libera el asiento si estaba pendiente; error simbolico si no.
  def cancelar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.cancelar_reserva(id, id_reserva)
    end
  end

  # PRE: recibe id del vuelo e id de la reserva.
  # POST: expira la reserva y libera el asiento si estaba pendiente; error simbolico si no.
  def expirar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.expirar_reserva(id, id_reserva)
    end
  end

  # PRE: recibe el id del vuelo; los Registry y el SupervisorVuelos estan corriendo.
  # POST: devuelve {:ok, pid} de un ServidorVuelo vivo para ese id (lo levanta si hace falta), o :error si el vuelo no existe.
  defp asegurar_servidor(id) do
    case Registry.lookup(Vuelos.Registro, id) do
      [{pid, _}] ->
        if Process.alive?(pid) do
          {:ok, pid}
        else
          reiniciar_servidor(id)
        end

      [] ->
        reiniciar_servidor(id)
    end
  end

  # PRE: recibe el id del vuelo; no hay servidor vivo para ese vuelo.
  # POST: levanta el servidor con el estado leido de DETS; devuelve {:ok, pid} o :error si no esta persistido.
  defp reiniciar_servidor(id) do
    case Persistencia.obtener(@tabla, {:vuelo, id}) do
      {:ok, vuelo} ->
        case DynamicSupervisor.start_child(
              Vuelos.SupervisorVuelos,
              {ServidorVuelo, vuelo}
            ) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            {:ok, pid}

          otro ->
            otro
        end

      :error ->
        :error
    end
  end
end