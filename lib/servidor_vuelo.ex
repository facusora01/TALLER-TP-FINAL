defmodule TpFinal.ServidorVuelo do
  use GenServer

  def start_link(vuelo) do
    GenServer.start_link(__MODULE__, vuelo)
  end

  def init(vuelo) do
    {:ok, vuelo}
  end

  def obtener_estado(pid) do
    GenServer.call(pid, :obtener_estado)
  end

  def obtener_asientos(pid) do
    GenServer.call(pid, :obtener_asientos)
  end

  def obtener_reservas(pid) do
    GenServer.call(pid, :obtener_reservas)
  end

  def reservar_asiento(pid, numero_asiento, usuario) do
    GenServer.call(
      pid,
      {:reservar_asiento, numero_asiento, usuario}
    )
  end

  def confirmar_reserva(pid, id_reserva) do
    GenServer.call(
      pid,
      {:confirmar_reserva, id_reserva}
    )
  end

  def cancelar_reserva(pid, id_reserva) do
    GenServer.call(
      pid,
      {:cancelar_reserva, id_reserva}
    )
  end

  def expirar_reserva(pid, id_reserva) do
    GenServer.call(
      pid,
      {:expirar_reserva, id_reserva}
    )
  end

  def handle_call(:obtener_estado, _from, vuelo) do
    {:reply, vuelo, vuelo}
  end

  def handle_call(:obtener_asientos, _from, vuelo) do
    {:reply, vuelo.asientos, vuelo}
  end

  def handle_call(:obtener_reservas, _from, vuelo) do
    {:reply, vuelo.reservas, vuelo}
  end

  def handle_call(
        {:reservar_asiento, numero_asiento, usuario},
        _from,
        vuelo
      ) do
    asiento =
      Enum.find(vuelo.asientos, fn asiento ->
        asiento.numero == numero_asiento
      end)

    if asiento.estado == :libre do
      id_reserva = vuelo.proxima_reserva_id

      reserva = %TpFinal.Reserva{
        id: id_reserva,
        numero_asiento: numero_asiento,
        usuario: usuario
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

      vuelo_actualizado = %{
        vuelo
        | asientos: nuevos_asientos,
          reservas: reservas_actualizadas,
          proxima_reserva_id: id_reserva + 1
      }

      {:reply, :ok, vuelo_actualizado}
    else
      {:reply, :ocupado, vuelo}
    end
  end

  def handle_call(
        {:confirmar_reserva, id_reserva},
        _from,
        vuelo
      ) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
          reserva_actualizada = %{
            reserva |
            estado: :confirmada
          }

          reservas_actualizadas =
            Map.put(
              vuelo.reservas,
              id_reserva,
              reserva_actualizada
            )

          vuelo_actualizado = %{
            vuelo |
            reservas: reservas_actualizadas
          }

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

  def handle_call(
        {:cancelar_reserva, id_reserva},
        _from,
        vuelo
      ) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
          reserva_actualizada = %{
            reserva |
            estado: :cancelada
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

          vuelo_actualizado = %{
            vuelo |
            reservas: reservas_actualizadas,
            asientos: nuevos_asientos
          }

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

  def handle_call(
        {:expirar_reserva, id_reserva},
        _from,
        vuelo
      ) do
    case Map.get(vuelo.reservas, id_reserva) do
      nil ->
        {:reply, :no_existe, vuelo}

      reserva ->
        if reserva.estado == :pendiente do
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

          vuelo_actualizado = %{
            vuelo |
            reservas: reservas_actualizadas,
            asientos: nuevos_asientos
          }

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end
end