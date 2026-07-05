defmodule Vuelos.ConexionWSTest do
  use ExUnit.Case, async: false

  setup do
    :dets.delete_all_objects(:usuarios)
    :ok = Supervisor.terminate_child(Vuelos.Supervisor, Vuelos.Usuarios)
    {:ok, _pid} = Supervisor.restart_child(Vuelos.Supervisor, Vuelos.Usuarios)

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

  test "la conexión reenvía al cliente los mensajes push {:enviar, texto}", contexto do
    %{conexion: conexion, ref: ref} = contexto

    pedir(conexion, ref, %{type: "registrar_usuario", request_id: "1", payload: %{nombre: "Ana"}})

    evento = Jason.encode!(%{type: "asiento_actualizado", payload: %{vuelo_id: 1, asiento: "3C"}})

    # OJO: :ranch.procs es un truco provisorio porque todavía no tenemos Registry
    # de conexiones. Cuando implementen el broadcast, cambien esto por el Registry
    # y borren esta parte, porque sino queda un test atado a las tripas de Cowboy.
    for pid <- :ranch.procs(Vuelos.ServidorWeb, :connections) do
      send(pid, {:enviar, evento})
    end

    assert_receive {:gun_ws, ^conexion, ^ref, {:text, recibido}}, 2_000
    assert %{"type" => "asiento_actualizado"} = Jason.decode!(recibido)
  end
end
