defmodule Vuelos.ServidorVuelo do
  @moduledoc "GenServer que administra el estado de un vuelo."

  use GenServer

  alias Vuelos.{Persistencia, Reserva, Pagos}
  
  # PRE: no recibe nada.
  # POST: devuelve el tiempo de expiracion en ms configurado (60s por defecto).
  defp tiempo_expiracion do
    Application.get_env(
      :vuelos,
      :tiempo_expiracion_ms,
      60_000
    )
  end

  # PRE: recibe un vuelo con id.
  # POST: devuelve la especificacion de hijo con restart :temporary (no se reinicia solo, se relanza bajo demanda).
  def child_spec(vuelo) do
    %{
      id: vuelo.id,
      start: {__MODULE__, :start_link, [vuelo]},
      restart: :temporary
    }
  end

  # PRE: recibe el vuelo completo; no hay otro servidor registrado para ese vuelo.
  # POST: arranca el proceso y lo registra en Vuelos.Registro bajo el id del vuelo; devuelve {:ok, pid}.
  def start_link(vuelo) do
    GenServer.start_link(
      __MODULE__,
      vuelo,
      name: {:via, Registry, {Vuelos.Registro, vuelo.id}}
    )
  end

  # PRE: recibe el id del vuelo; el servidor de ese vuelo esta vivo.
  # POST: devuelve el estado completo del vuelo. No modifica nada.
  def obtener_estado(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_estado)
  end

  # PRE: recibe el id del vuelo; el servidor de ese vuelo esta vivo.
  # POST: devuelve la lista de asientos. No modifica nada.
  def obtener_asientos(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_asientos)
  end

  # PRE: recibe el id del vuelo; el servidor de ese vuelo esta vivo.
  # POST: devuelve el mapa de reservas. No modifica nada.
  def obtener_reservas(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_reservas)
  end

  # PRE: recibe id del vuelo, numero de asiento y el usuario; el servidor del vuelo esta vivo.
  # POST: reserva el asiento y devuelve {:ok, reserva_id} si estaba libre; :ocupado o :asiento_no_existe si no.
  def reservar_asiento(id_vuelo, numero_asiento, usuario) do
    GenServer.call(
      via(id_vuelo),
      {:reservar_asiento, numero_asiento, usuario}
    )
  end

  # PRE: recibe id del vuelo e id de la reserva; el servidor del vuelo esta vivo.
  # POST: inicia el pago y devuelve :ok si la reserva estaba pendiente; :no_existe o :estado_invalido si no.
  def confirmar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:confirmar_reserva, id_reserva}
    )
  end

  # PRE: recibe id del vuelo e id de la reserva; el servidor del vuelo esta vivo.
  # POST: cancela la reserva y libera el asiento si estaba pendiente; devuelve :no_existe o :estado_invalido si no.
  def cancelar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:cancelar_reserva, id_reserva}
    )
  end

  # PRE: recibe id del vuelo e id de la reserva; el servidor del vuelo esta vivo.
  # POST: expira la reserva y libera el asiento si estaba pendiente; devuelve :no_existe o :estado_invalido si no.
  def expirar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:expirar_reserva, id_reserva}
    )
  end

  # PRE: recibe el id del vuelo.
  # POST: devuelve la via-tuple para ubicar el proceso de ese vuelo en el Registry.
  defp via(id_vuelo) do
    {:via, Registry, {Vuelos.Registro, id_vuelo}}
  end

  # PRE: recibe el vuelo (leido de DETS o nuevo).
  # POST: deja el vuelo como estado inicial del proceso.
  @impl true
  def init(vuelo) do
    {:ok, vuelo}
  end

  # PRE: recibe el vuelo; la tabla :vuelos esta abierta.
  # POST: guarda el vuelo en disco (DETS) y lo devuelve sin cambios.
  defp persistir(vuelo) do
    Persistencia.guardar(
      :vuelos,
      {:vuelo, vuelo.id},
      vuelo
    )

    vuelo
  end

  # PRE: llega el call :obtener_estado.
  # POST: responde el vuelo completo; el estado no cambia.
  @impl true
  def handle_call(:obtener_estado, _from, vuelo) do
    {:reply, vuelo, vuelo}
  end

  # PRE: llega el call :obtener_asientos.
  # POST: responde la lista de asientos; el estado no cambia.
  @impl true
  def handle_call(:obtener_asientos, _from, vuelo) do
    {:reply, vuelo.asientos, vuelo}
  end

  # PRE: llega el call :obtener_reservas.
  # POST: responde el mapa de reservas; el estado no cambia.
  @impl true
  def handle_call(:obtener_reservas, _from, vuelo) do
    {:reply, vuelo.reservas, vuelo}
  end

  # PRE: recibe numero de asiento y usuario; el asiento existe y esta :libre (si no, responde error sin cambiar nada).
  # POST: crea la reserva :pendiente con timer de expiracion, marca el asiento :reservado,
  #       persiste el vuelo, hace broadcast y responde {:ok, reserva_id}.
  @impl true
  def handle_call({:reservar_asiento, numero_asiento, usuario}, _from, vuelo) do
    asiento =
      Enum.find(vuelo.asientos, fn asiento ->
        asiento.numero == numero_asiento
      end)

    cond do
      asiento == nil ->
        {:reply, :asiento_no_existe, vuelo}

      asiento.estado != :libre ->
        {:reply, :ocupado, vuelo}

      true ->
        id_reserva = vuelo.proxima_reserva_id

        timer_ref =
          Process.send_after(
            self(),
            {:expirar_reserva_timeout, id_reserva},
            tiempo_expiracion()
          )

        reserva = %Reserva{
          id: id_reserva,
          numero_asiento: numero_asiento,
          usuario: usuario,
          timer_ref: timer_ref,
          creada_en: DateTime.utc_now()
        }

        reservas_actualizadas =
          Map.put(vuelo.reservas, id_reserva, reserva)

        nuevos_asientos =
          Enum.map(vuelo.asientos, fn asiento ->
            if asiento.numero == numero_asiento do
              %{asiento | estado: :reservado}
            else
              asiento
            end
          end)

        vuelo_actualizado =
          %{vuelo |
            asientos: nuevos_asientos,
            reservas: reservas_actualizadas,
            proxima_reserva_id: id_reserva + 1}
          |> persistir()

        Vuelos.Broadcast.notificar(vuelo_actualizado)

        {:reply, {:ok, id_reserva}, vuelo_actualizado}
    end
  end

  # PRE: recibe el id de la reserva; la reserva existe y esta :pendiente (si no, responde error).
  # POST: lanza el pago en segundo plano y responde :ok; el resultado llegara como {:pago_aprobado, id}.
  @impl true
  def handle_call({:confirmar_reserva, id_reserva}, _from, vuelo) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
          Pagos.procesar(id_reserva)

          {:reply, :ok, vuelo}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

  # PRE: recibe el id de la reserva; la reserva existe y esta :pendiente (si no, responde error).
  # POST: cancela el timer, pasa la reserva a :cancelada y el asiento a :libre, persiste y hace broadcast.
  @impl true
  def handle_call({:cancelar_reserva, id_reserva}, _from, vuelo) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
          Process.cancel_timer(reserva.timer_ref)

          reserva_actualizada = %{
            reserva |
            estado: :cancelada,
            timer_ref: nil
          }

          reservas_actualizadas =
            Map.put(
              vuelo.reservas,
              id_reserva,
              reserva_actualizada
            )

          nuevos_asientos =
            Enum.map(vuelo.asientos, fn asiento ->
              if asiento.numero == reserva.numero_asiento do
                %{asiento | estado: :libre}
              else
                asiento
              end
            end)

          vuelo_actualizado =
            %{vuelo |
              reservas: reservas_actualizadas,
              asientos: nuevos_asientos}
            |> persistir()

          Vuelos.Broadcast.notificar(vuelo_actualizado)
          Vuelos.Broadcast.notificar_reserva(
            vuelo_actualizado,
            reserva_actualizada
          )

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

  # PRE: recibe el id de la reserva; la reserva existe y esta :pendiente (si no, responde error).
  # POST: pasa la reserva a :expirada y el asiento a :libre, persiste y hace broadcast.
  @impl true
  def handle_call({:expirar_reserva, id_reserva}, _from, vuelo) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
          reserva_actualizada = %{
            reserva |
            estado: :expirada,
            timer_ref: nil
          }

          reservas_actualizadas =
            Map.put(
              vuelo.reservas,
              id_reserva,
              reserva_actualizada
            )

          nuevos_asientos =
            Enum.map(vuelo.asientos, fn asiento ->
              if asiento.numero == reserva.numero_asiento do
                %{asiento | estado: :libre}
              else
                asiento
              end
            end)

          vuelo_actualizado =
            %{vuelo |
              reservas: reservas_actualizadas,
              asientos: nuevos_asientos}
            |> persistir()

          Vuelos.Broadcast.notificar(vuelo_actualizado)
          Vuelos.Broadcast.notificar_reserva(
            vuelo_actualizado,
            reserva_actualizada
          )
          
          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
      end
    end
  end

  # PRE: recibe {:expirar_reserva_timeout, id}: vencio el timer de una reserva (mensaje que el proceso se mando a si mismo).
  # POST: si la reserva seguia :pendiente, la pasa a :expirada y el asiento a :libre, persiste y hace broadcast; si no, ignora el mensaje.
  @impl true
  def handle_info({:expirar_reserva_timeout, id_reserva}, vuelo) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:noreply, vuelo}

      %{estado: :pendiente} ->
        reserva = vuelo.reservas[id_reserva]

        reserva_actualizada = %{
          reserva |
          estado: :expirada
        }

        reservas_actualizadas =
          Map.put(
            vuelo.reservas,
            id_reserva,
            reserva_actualizada
          )

        nuevos_asientos =
          Enum.map(vuelo.asientos, fn asiento ->
            if asiento.numero == reserva.numero_asiento do
              %{asiento | estado: :libre}
            else
              asiento
            end
          end)

        vuelo_actualizado =
          %{vuelo |
            reservas: reservas_actualizadas,
            asientos: nuevos_asientos}
          |> persistir()

        Vuelos.Broadcast.notificar(vuelo_actualizado)
        Vuelos.Broadcast.notificar_reserva(
          vuelo_actualizado,
          reserva_actualizada
        )

        {:noreply, vuelo_actualizado}

      _ ->
        {:noreply, vuelo}
    end
  end

  # PRE: recibe {:pago_aprobado, id}: la tarea de pago termino y aviso el resultado.
  # POST: si la reserva seguia :pendiente, la pasa a :confirmada y el asiento a :confirmado,
  #       persiste y hace broadcast; si ya expiro o se cancelo, ignora el mensaje.
  @impl true
  def handle_info({:pago_aprobado, id_reserva}, vuelo) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:noreply, vuelo}

      %{estado: :pendiente} = reserva ->
        Process.cancel_timer(reserva.timer_ref)

        reserva_actualizada = %{
          reserva |
          estado: :confirmada,
          timer_ref: nil
        }

        reservas_actualizadas =
          Map.put(
            vuelo.reservas,
            id_reserva,
            reserva_actualizada
          )

        nuevos_asientos =
          Enum.map(vuelo.asientos, fn asiento ->
            if asiento.numero == reserva.numero_asiento do
              %{asiento | estado: :confirmado}
            else
              asiento
            end
          end)

        vuelo_actualizado =
          %{vuelo |
            reservas: reservas_actualizadas,
            asientos: nuevos_asientos}
          |> persistir()

        Vuelos.Broadcast.notificar(vuelo_actualizado)
        Vuelos.Broadcast.notificar_reserva(
          vuelo_actualizado,
          reserva_actualizada
        )

        {:noreply, vuelo_actualizado}

      _ ->
        {:noreply, vuelo}
    end
  end
end