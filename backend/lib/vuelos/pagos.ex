defmodule Vuelos.Pagos do
  @moduledoc """
  Pago simulado: se procesa en una tarea supervisada, tarda entre 1 y 5
  segundos elegidos al azar y le avisa el resultado al proceso interesado.
  """

  @demora_por_defecto {1_000, 5_000}

  @doc "Inicia el pago de una reserva; el resultado llega como mensaje al proceso que llama."
  def procesar(reserva_id, destinatario \\ self()) do
    Task.Supervisor.start_child(Vuelos.SupervisorTareas, fn ->
      Process.sleep(demora())
      send(destinatario, {:pago_aprobado, reserva_id})
    end)
  end

  @doc "Rango de demora configurado, en milisegundos."
  def rango_demora do
    Application.get_env(:vuelos, :demora_pago_ms, @demora_por_defecto)
  end

  defp demora do
    {minimo, maximo} = rango_demora()
    Enum.random(minimo..maximo)
  end
end
