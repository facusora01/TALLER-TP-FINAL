defmodule Vuelos.RecuperacionTest do
  use ExUnit.Case, async: false

  alias Vuelos.{
    Usuarios,
    GestorVuelos,
    Persistencia
  }

  setup do
    :dets.delete_all_objects(:usuarios)
    :dets.delete_all_objects(:vuelos)

    Enum.each(DynamicSupervisor.which_children(Vuelos.SupervisorVuelos), fn
      {_, pid, _, _} ->
        Process.exit(pid, :kill)
    end)

    Vuelos.Seeds.cargar()

    :ok
  end

  test "el estado del vuelo se recupera luego de reiniciar su proceso" do
    vuelo_id = "ARC-001"

    Application.put_env(:vuelos, :demora_pago_ms, {50, 50})
    on_exit(fn -> Application.delete_env(:vuelos, :demora_pago_ms) end)

    {:ok, usuario} =
      Usuarios.registrar("Denisse")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        vuelo_id,
        1,
        usuario
      )


    assert :ok ==
             GestorVuelos.confirmar_reserva(
               vuelo_id,
               reserva_id
             )

    # El pago es asíncrono: esperamos a que la reserva quede confirmada antes
    # de sincronizar a disco y reiniciar el proceso.
    esperar_confirmada(vuelo_id, reserva_id)

    Persistencia.sincronizar()

    [{pid, _}] =
      Registry.lookup(
        Vuelos.Registro,
        vuelo_id
      )

    ref = Process.monitor(pid)

    Process.exit(pid, :kill)

    assert_receive {:DOWN, ^ref, _, _, _}

    {:ok, vuelo} =
      GestorVuelos.obtener_estado(vuelo_id)

    assert {:ok, _} =
             Usuarios.obtener(usuario.id)

    assert vuelo.id == vuelo_id

    reserva =
      Map.fetch!(vuelo.reservas, reserva_id)

    assert reserva.estado == :confirmada

    asiento =
      Enum.find(
        vuelo.asientos,
        &(&1.numero == 1)
      )

    assert asiento.estado == :confirmado
  end

  test "las reservas pendientes permanecen pendientes luego de reiniciar el proceso" do
    vuelo_id = "ARC-002"

    {:ok, usuario} =
      Usuarios.registrar("Ana")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        vuelo_id,
        2,
        usuario
      )

    Persistencia.sincronizar()

    [{pid, _}] =
      Registry.lookup(
        Vuelos.Registro,
        vuelo_id
      )

    ref = Process.monitor(pid)

    Process.exit(pid, :kill)

    assert_receive {:DOWN, ^ref, _, _, _}

    {:ok, vuelo} =
      GestorVuelos.obtener_estado(vuelo_id)

    reserva =
      Map.fetch!(vuelo.reservas, reserva_id)

    assert reserva.estado == :pendiente

    asiento =
      Enum.find(
        vuelo.asientos,
        &(&1.numero == 2)
      )

    assert asiento.estado == :reservado
  end

  # Espera (con reintentos) a que el pago asíncrono confirme la reserva.
  defp esperar_confirmada(vuelo_id, reserva_id, intentos \\ 50) do
    {:ok, vuelo} = GestorVuelos.obtener_estado(vuelo_id)

    cond do
      vuelo.reservas[reserva_id].estado == :confirmada ->
        :ok

      intentos == 0 ->
        flunk("la reserva no se confirmó a tiempo")

      true ->
        Process.sleep(20)
        esperar_confirmada(vuelo_id, reserva_id, intentos - 1)
    end
  end
end