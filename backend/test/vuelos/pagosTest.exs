defmodule Vuelos.PagosTest do
  use ExUnit.Case, async: false

  alias Vuelos.Pagos

  test "el pago no se aprueba de inmediato: respeta la demora mínima" do
    {minimo, _maximo} = Pagos.rango_demora()
    inicio = System.monotonic_time(:millisecond)

    Pagos.procesar(99)

    refute_received {:pago_aprobado, 99}
    assert_receive {:pago_aprobado, 99}, 2_000
    assert System.monotonic_time(:millisecond) - inicio >= minimo
  end

  test "el resultado llega al destinatario indicado, no a quien lo inicia" do
    quien_prueba = self()

    destinatario =
      spawn(fn ->
        receive do
          mensaje -> send(quien_prueba, {:recibido, mensaje})
        end
      end)

    Pagos.procesar(7, destinatario)

    assert_receive {:recibido, {:pago_aprobado, 7}}, 2_000
    refute_received {:pago_aprobado, 7}
  end

  test "cada pago corre en una tarea supervisada por Vuelos.SupervisorTareas" do
    {:ok, pid} = Pagos.procesar(1)

    assert pid in Task.Supervisor.children(Vuelos.SupervisorTareas)
    assert_receive {:pago_aprobado, 1}, 2_000
  end

  test "pagos concurrentes avisan cada uno con su reserva" do
    Pagos.procesar(10)
    Pagos.procesar(20)

    assert_receive {:pago_aprobado, 10}, 2_000
    assert_receive {:pago_aprobado, 20}, 2_000
  end
end
