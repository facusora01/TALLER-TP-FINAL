defmodule Vuelos.ServidorVuelo do
  @moduledoc "GenServer que administra el estado de un vuelo."

  use GenServer

  alias Vuelos.{Persistencia, Reserva}


  def child_spec(vuelo) do
    %{
      id: vuelo.id,
      start: {__MODULE__, :start_link, [vuelo]},
      restart: :temporary
    }
  end

  def start_link(vuelo) do
    GenServer.start_link(
      __MODULE__,
      vuelo,
      name: {:via, Registry, {Vuelos.Registro, vuelo.id}}
    )
  end

  def obtener_estado(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_estado)
  end

  def obtener_asientos(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_asientos)
  end

  def obtener_reservas(id_vuelo) do
    GenServer.call(via(id_vuelo), :obtener_reservas)
  end

  def reservar_asiento(id_vuelo, numero_asiento, usuario) do
    GenServer.call(
      via(id_vuelo),
      {:reservar_asiento, numero_asiento, usuario}
    )
  end

  def confirmar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:confirmar_reserva, id_reserva}
    )
  end

  def cancelar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:cancelar_reserva, id_reserva}
    )
  end

  def expirar_reserva(id_vuelo, id_reserva) do
    GenServer.call(
      via(id_vuelo),
      {:expirar_reserva, id_reserva}
    )
  end

  defp via(id_vuelo) do
    {:via, Registry, {Vuelos.Registro, id_vuelo}}
  end

  @impl true
  def init(vuelo) do
    {:ok, vuelo}
  end

  defp persistir(vuelo) do
    Persistencia.guardar(
      :vuelos,
      {:vuelo, vuelo.id},
      vuelo
    )

    vuelo
  end

  @impl true
  def handle_call(:obtener_estado, _from, vuelo) do
    {:reply, vuelo, vuelo}
  end

    @impl true
  def handle_call(:obtener_asientos, _from, vuelo) do
    {:reply, vuelo.asientos, vuelo}
  end

  @impl true
  def handle_call(:obtener_reservas, _from, vuelo) do
    {:reply, vuelo.reservas, vuelo}
  end

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

        reserva = %Reserva{
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

    @impl true
  def handle_call({:confirmar_reserva, id_reserva}, _from, vuelo) do
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

          vuelo_actualizado =
            %{vuelo |
              reservas: reservas_actualizadas}
            |> persistir()

          Vuelos.Broadcast.notificar(vuelo_actualizado)

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

    @impl true
  def handle_call({:cancelar_reserva, id_reserva}, _from, vuelo) do
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

          vuelo_actualizado =
            %{vuelo |
              reservas: reservas_actualizadas,
              asientos: nuevos_asientos}
            |> persistir()

          Vuelos.Broadcast.notificar(vuelo_actualizado)

          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
        end
    end
  end

    @impl true
  def handle_call({:expirar_reserva, id_reserva}, _from, vuelo) do
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

          vuelo_actualizado =
            %{vuelo |
              reservas: reservas_actualizadas,
              asientos: nuevos_asientos}
            |> persistir()

          Vuelos.Broadcast.notificar(vuelo_actualizado)
          
          {:reply, :ok, vuelo_actualizado}
        else
          {:reply, :estado_invalido, vuelo}
      end
    end
  end
end