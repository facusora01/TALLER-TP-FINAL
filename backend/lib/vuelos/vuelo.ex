defmodule Vuelos.Vuelo do
  @moduledoc "Representa el estado completo de un vuelo."

    defstruct [
    :id,
    :aerolinea_id,
    :origen,
    :destino,
    :fecha,
    :hora,
    :precio,
    :asientos_totales,
    :asientos,
    reservas: %{},
    proxima_reserva_id: 1
    ]
end