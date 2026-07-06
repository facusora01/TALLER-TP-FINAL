defmodule Vuelos.ProtocoloTest do
  use ExUnit.Case, async: false

  alias Vuelos.Protocolo

  setup do
    :dets.delete_all_objects(:usuarios)
    #:ok = Supervisor.terminate_child(Vuelos.Supervisor, Vuelos.Usuarios)
    #{:ok, _pid} = Supervisor.restart_child(Vuelos.Supervisor, Vuelos.Usuarios)
    :ok = Supervisor.terminate_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)
    {:ok, _pid} = Supervisor.restart_child(Vuelos.SupervisorDominio, Vuelos.Usuarios)
    :ok
  end

  defp atender!(mensaje) do
    mensaje |> Jason.encode!() |> Protocolo.atender() |> Jason.decode!()
  end

  test "registrar_usuario responde con el usuario creado y el mismo request_id" do
    respuesta =
      atender!(%{type: "registrar_usuario", request_id: "1", payload: %{nombre: "Ana"}})

    assert %{
             "type" => "registrar_usuario_ok",
             "request_id" => "1",
             "payload" => %{"usuario_id" => 1, "nombre" => "Ana"}
           } = respuesta
  end

  test "obtener_usuario devuelve el usuario, o USUARIO_NO_EXISTE" do
    atender!(%{type: "registrar_usuario", request_id: "1", payload: %{nombre: "Ana"}})

    ok = atender!(%{type: "obtener_usuario", request_id: "2", payload: %{usuario_id: 1}})
    assert %{"type" => "obtener_usuario_ok", "payload" => %{"nombre" => "Ana"}} = ok

    error = atender!(%{type: "obtener_usuario", request_id: "3", payload: %{usuario_id: 99}})

    assert %{
             "type" => "error",
             "request_id" => "3",
             "payload" => %{"codigo" => "USUARIO_NO_EXISTE"}
           } = error
  end

  test "un type desconocido responde error TIPO_DESCONOCIDO" do
    respuesta = atender!(%{type: "volar_gratis", request_id: "4", payload: %{}})

    assert %{
             "type" => "error",
             "request_id" => "4",
             "payload" => %{"codigo" => "TIPO_DESCONOCIDO"}
           } = respuesta
  end

  test "JSON inválido o sin type responde error MENSAJE_INVALIDO" do
    invalido = Protocolo.atender("esto no es json") |> Jason.decode!()
    assert %{"type" => "error", "payload" => %{"codigo" => "MENSAJE_INVALIDO"}} = invalido

    sin_tipo = atender!(%{request_id: "5", payload: %{}})
    assert %{"type" => "error", "payload" => %{"codigo" => "MENSAJE_INVALIDO"}} = sin_tipo
  end
end
