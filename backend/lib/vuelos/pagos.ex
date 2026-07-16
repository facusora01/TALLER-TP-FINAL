defmodule Vuelos.Pagos do
  @moduledoc """
  Pago simulado: se procesa en una tarea supervisada, tarda entre 1 y 5
  segundos elegidos al azar y le avisa el resultado al proceso interesado.
  """

  @demora_por_defecto {1_000, 5_000}

  @doc "Inicia el pago de una reserva; el resultado llega como mensaje al proceso que llama."
  # PRE: recibe el id de la reserva y el pid destinatario; el SupervisorTareas esta corriendo.
  # POST: lanza la tarea de pago; tras la demora, el destinatario recibe {:pago_aprobado, reserva_id}.
  def procesar(reserva_id, destinatario \\ self()) do
    Task.Supervisor.start_child(Vuelos.SupervisorTareas, fn ->
      Process.sleep(demora())
      send(destinatario, {:pago_aprobado, reserva_id})
    end)
  end

  @doc "Rango de demora configurado, en milisegundos."
  # PRE: no recibe nada.
  # POST: devuelve {min, max} en ms (por defecto {1000, 5000}).
  def rango_demora do
    Application.get_env(:vuelos, :demora_pago_ms, @demora_por_defecto)
  end

  # PRE: el rango configurado cumple min <= max.
  # POST: devuelve una demora aleatoria dentro del rango.
  defp demora do
    {minimo, maximo} = rango_demora()
    Enum.random(minimo..maximo)
  end
end
