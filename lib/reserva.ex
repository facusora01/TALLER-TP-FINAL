defmodule TpFinal.Reserva do
  defstruct [
    :id,
    :numero_asiento,
    :usuario,
    estado: :pendiente
  ]
end