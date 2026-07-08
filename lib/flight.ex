defmodule TpFinal.Flight do
  defstruct [
    :id,
    :aerolinea,
    :origen,
    :destino,
    :fecha,
    :precio,
    :asientos,
    reservas: %{},
    proxima_reserva_id: 1
  ]
end