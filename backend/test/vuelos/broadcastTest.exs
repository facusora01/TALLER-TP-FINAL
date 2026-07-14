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
end