defmodule Vuelos.Reserva do
  @moduledoc "Representa una reserva de un asiento."

  defstruct [
    :id,
    :numero_asiento,
    :usuario,
    :timer_ref,
    :creada_en,
    estado: :pendiente
  ]
end