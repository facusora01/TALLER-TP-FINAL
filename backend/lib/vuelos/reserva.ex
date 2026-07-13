defmodule Vuelos.Reserva do
  @moduledoc "Representa una reserva de un asiento."

  defstruct [
    :id,
    :numero_asiento,
    :usuario,
    estado: :pendiente
  ]
end