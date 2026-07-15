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
    :avion,
    reservas: %{},
    proxima_reserva_id: 1,
    # asientos por grupo de columnas, con pasillo entre grupos (ej: [3,3] o [2,4,2])
    distribucion: [3, 3]
    ]
end