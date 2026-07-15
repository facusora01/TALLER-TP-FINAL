defmodule Vuelos.BroadcastTest do
  use ExUnit.Case, async: false

  alias Vuelos.{
    Broadcast,
    Usuarios,
    GestorVuelos
  }

  setup do
    :dets.delete_all_objects(:usuarios)
    :dets.delete_all_objects(:vuelos)

    Enum.each(DynamicSupervisor.which_children(Vuelos.SupervisorVuelos), fn
      {_, pid, _, _} ->
        Process.exit(pid, :kill)
    end)

    Vuelos.Seeds.cargar()

    on_exit(fn ->
      Enum.each(
        DynamicSupervisor.which_children(Vuelos.SupervisorVuelos),
        fn {_, pid, _, _} ->
          Process.exit(pid, :kill)
        end
      )
    end)

    :ok
  end

  test "los clientes suscriptos reciben una actualización al reservar un asiento" do
    vuelo_id = "ARC-001"

    {:ok, usuario} =
      Usuarios.registrar("Denisse")

    {:ok, _} =
      Broadcast.subscribir(vuelo_id, self())

    {:ok, _reserva_id} =
      GestorVuelos.reservar_asiento(
        vuelo_id,
        1,
        usuario
      )

    assert_receive {:enviar, mensaje}

    {:ok, json} =
      Jason.decode(mensaje)

    assert json["type"] == "vuelo_actualizado"

    payload = json["payload"]

    assert payload["vuelo_id"] == vuelo_id
    assert is_list(payload["asientos"])
  end

  test "todos los clientes suscriptos reciben la actualización" do
    vuelo_id = "ARC-001"

    padre = self()

    cliente =
      spawn(fn ->
        Broadcast.subscribir(vuelo_id)

        receive do
          mensaje ->
            send(padre, {:cliente_recibio, mensaje})
        end
      end)

    {:ok, _} =
      Broadcast.subscribir(vuelo_id, self())

    {:ok, usuario} =
      Usuarios.registrar("Ana")

    {:ok, _} =
      GestorVuelos.reservar_asiento(
        vuelo_id,
        2,
        usuario
      )

    assert_receive {:enviar, _}

    assert_receive {:cliente_recibio, {:enviar, _}}

    Process.exit(cliente, :kill)
  end

  test "al confirmar una reserva se envía reserva_actualizada" do
    # Pago rápido para no esperar; se limpia al terminar para no filtrar la
    # demora a otros tests que comparten la config de la aplicación.
    Application.put_env(:vuelos, :demora_pago_ms, {20, 20})
    on_exit(fn -> Application.delete_env(:vuelos, :demora_pago_ms) end)

    vuelo_id = "ARC-001"

    {:ok, _} =
      Broadcast.subscribir(vuelo_id, self())

    {:ok, usuario} =
      Usuarios.registrar("Pedro")

    {:ok, reserva_id} =
      GestorVuelos.reservar_asiento(
        vuelo_id,
        3,
        usuario
      )

    # descarto el broadcast de la reserva
    assert_receive {:enviar, _}

    :ok =
      GestorVuelos.confirmar_reserva(
        vuelo_id,
        reserva_id
      )

    # Al aprobarse el pago (asíncrono) llegan el broadcast del vuelo y el de la reserva.
    # broadcast del vuelo
    assert_receive {:enviar, _}, 2_000

    # broadcast específico de la reserva
    assert_receive {:enviar, mensaje}, 2_000

    {:ok, json} =
      Jason.decode(mensaje)

    assert json["type"] == "reserva_actualizada"
    assert json["payload"]["estado"] == "confirmada"
  end
end