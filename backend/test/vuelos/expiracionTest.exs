defmodule Vuelos.ExpiracionTest do
  use ExUnit.Case, async: false

  alias Vuelos.{
    Usuarios,
    GestorVuelos,
    ServidorVuelo
  }

  setup do
    :dets.delete_all_objects(:usuarios)
    :dets.delete_all_objects(:vuelos)

    Enum.each(
      DynamicSupervisor.which_children(Vuelos.SupervisorVuelos),
      fn
        {_, pid, _, _} ->
          Process.exit(pid, :kill)
      end
    )

    Vuelos.Seeds.cargar()

    on_exit(fn ->
      Application.delete_env(:vuelos, :tiempo_expiracion_ms)
      Application.delete_env(:vuelos, :demora_pago_ms)
    end)

    :ok
  end

  test "una reserva pendiente expira automáticamente" do
    Application.put_env(:vuelos, :tiempo_expiracion_ms, 100)
    Application.put_env(:vuelos, :demora_pago_ms, {1000, 1000})

    {:ok, usuario} =
      Usuarios.registrar("Denisse")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        "ARC-001",
        1,
        usuario
      )

    Process.sleep(200)

    vuelo =
      ServidorVuelo.obtener_estado("ARC-001")

    reserva =
      vuelo.reservas[reserva_id]

    assert reserva.estado == :expirada

    asiento =
      Enum.find(vuelo.asientos, &(&1.numero == 1))

    assert asiento.estado == :libre
  end

  test "el pago simulado confirma automáticamente la reserva" do
    Application.put_env(:vuelos, :tiempo_expiracion_ms, 1000)
    Application.put_env(:vuelos, :demora_pago_ms, {100, 100})

    {:ok, usuario} =
      Usuarios.registrar("Ana")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        "ARC-001",
        2,
        usuario
      )

    # El pago se dispara al confirmar y confirma la reserva de forma asíncrona.
    :ok = GestorVuelos.confirmar_reserva("ARC-001", reserva_id)

    Process.sleep(200)

    vuelo =
      ServidorVuelo.obtener_estado("ARC-001")

    reserva =
      vuelo.reservas[reserva_id]

    assert reserva.estado == :confirmada

    asiento =
      Enum.find(vuelo.asientos, &(&1.numero == 2))

    assert asiento.estado == :confirmado
  end

  test "una reserva confirmada por el pago no expira aunque venza el timeout" do
    Application.put_env(:vuelos, :tiempo_expiracion_ms, 300)
    Application.put_env(:vuelos, :demora_pago_ms, {100, 100})

    {:ok, usuario} =
      Usuarios.registrar("Carlos")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        "ARC-001",
        3,
        usuario
      )

    # El pago (100 ms) confirma antes de que venza el timer (300 ms); una vez
    # confirmada, el timeout que llega después no debe volver a tocarla.
    :ok = GestorVuelos.confirmar_reserva("ARC-001", reserva_id)

    Process.sleep(500)

    vuelo =
      ServidorVuelo.obtener_estado("ARC-001")

    reserva =
      vuelo.reservas[reserva_id]

    assert reserva.estado == :confirmada

    asiento =
      Enum.find(vuelo.asientos, &(&1.numero == 3))

    assert asiento.estado == :confirmado
  end
end