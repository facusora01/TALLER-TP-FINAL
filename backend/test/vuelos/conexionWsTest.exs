defmodule Vuelos.ConexionWSTest do
  use ExUnit.Case, async: false

  setup do
    :dets.delete_all_objects(:usuarios)
    #:ok = Supervisor.terminate_child(Vuelos.Supervisor, Vuelos.Usuarios)
    #{:ok, _pid} = Supervisor.restart_child(Vuelos.Supervisor, Vuelos.Usuarios)
    :ok = Supervisor.terminate_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)
    {:ok, _pid} = Supervisor.restart_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)

    # Vuelos limpios en cada corrida: el asiento a reservar arranca libre.
    :dets.delete_all_objects(:vuelos)

    Enum.each(DynamicSupervisor.which_children(Vuelos.SupervisorVuelos), fn
      {_, pid, _, _} -> Process.exit(pid, :kill)
    end)

    Vuelos.Seeds.cargar()

    on_exit(fn ->
      Enum.each(DynamicSupervisor.which_children(Vuelos.SupervisorVuelos), fn
        {_, pid, _, _} -> Process.exit(pid, :kill)
      end)
    end)

    {:ok, conexion} = :gun.open(~c"localhost", Vuelos.ServidorWeb.puerto())
    {:ok, _protocolo} = :gun.await_up(conexion)
    ref = :gun.ws_upgrade(conexion, "/ws")
    assert_receive {:gun_upgrade, ^conexion, ^ref, ["websocket"], _cabeceras}, 2_000

    on_exit(fn -> :gun.close(conexion) end)
    {:ok, conexion: conexion, ref: ref}
  end

  defp pedir(conexion, ref, mensaje) do
    :ok = :gun.ws_send(conexion, ref, {:text, Jason.encode!(mensaje)})
    assert_receive {:gun_ws, ^conexion, ^ref, {:text, respuesta}}, 2_000
    Jason.decode!(respuesta)
  end

  test "el cliente registra un usuario por WebSocket y recibe la respuesta", contexto do
    respuesta =
      pedir(contexto.conexion, contexto.ref, %{
        type: "registrar_usuario",
        request_id: "1",
        payload: %{nombre: "Ana"}
      })

    assert %{
             "type" => "registrar_usuario_ok",
             "request_id" => "1",
             "payload" => %{"usuario_id" => 1, "nombre" => "Ana"}
           } = respuesta
  end

  test "un mensaje inválido recibe un error sin cortar la conexión", contexto do
    %{conexion: conexion, ref: ref} = contexto

    :ok = :gun.ws_send(conexion, ref, {:text, "no es json"})
    assert_receive {:gun_ws, ^conexion, ^ref, {:text, error}}, 2_000
    assert %{"type" => "error"} = Jason.decode!(error)

    respuesta =
      pedir(conexion, ref, %{type: "registrar_usuario", request_id: "2", payload: %{nombre: "Beto"}})

    assert %{"type" => "registrar_usuario_ok"} = respuesta
  end

  test "dos clientes conectados a la vez operan sin pisarse", contexto do
    {:ok, otra} = :gun.open(~c"localhost", Vuelos.ServidorWeb.puerto())
    {:ok, _protocolo} = :gun.await_up(otra)
    otra_ref = :gun.ws_upgrade(otra, "/ws")
    assert_receive {:gun_upgrade, ^otra, ^otra_ref, ["websocket"], _cabeceras}, 2_000
    on_exit(fn -> :gun.close(otra) end)

    r1 =
      pedir(contexto.conexion, contexto.ref, %{
        type: "registrar_usuario",
        request_id: "1",
        payload: %{nombre: "Ana"}
      })

    r2 = pedir(otra, otra_ref, %{type: "registrar_usuario", request_id: "1", payload: %{nombre: "Beto"}})

    ids = [r1["payload"]["usuario_id"], r2["payload"]["usuario_id"]]
    assert Enum.sort(ids) == [1, 2]
  end

  test "un cliente suscripto recibe por WebSocket el broadcast al reservarse un asiento", contexto do
    %{conexion: conexion, ref: ref} = contexto

    vuelo_id = "ARC-001"

    # El cliente se suscribe al vuelo.
    assert %{"type" => "suscribir_vuelo_ok"} =
             pedir(conexion, ref, %{
               type: "suscribir_vuelo",
               request_id: "1",
               payload: %{vuelo_id: vuelo_id}
             })

    # Una reserva dispara el broadcast.
    {:ok, usuario} = Vuelos.Usuarios.registrar("Ana")
    {:ok, _reserva_id} = Vuelos.GestorVuelos.reservar_asiento(vuelo_id, 1, usuario)

    # La actualización llega al cliente por el WebSocket.
    assert_receive {:gun_ws, ^conexion, ^ref, {:text, recibido}}, 2_000

    assert %{"type" => "vuelo_actualizado", "payload" => %{"vuelo_id" => ^vuelo_id}} =
             Jason.decode!(recibido)
  end
end
