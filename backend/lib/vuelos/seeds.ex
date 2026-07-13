defmodule Vuelos.Seeds do
  @moduledoc "Carga los datos iniciales de aerolíneas y vuelos si no existen todavía."

  alias Vuelos.Persistencia
  alias Vuelos.Vuelo

  def cargar do
    if Persistencia.todos(:vuelos) == [] do
      insertar_aerolineas()
      insertar_vuelos()
    end
  end

  # --- Aerolíneas ---

  defp insertar_aerolineas do
    Enum.each(aerolineas(), fn a ->
      Persistencia.guardar(:vuelos, {:aerolinea, a.id}, a)
    end)
  end

  defp aerolineas do
    [
      %{id: "ARC", nombre: "Aerolíneas del Cóndor", codigo: "ARC", color: "#2196F3"},
      %{id: "FLS", nombre: "FlySur",                codigo: "FLS", color: "#F5A623"},
      %{id: "PAM", nombre: "Pampa Air",             codigo: "PAM", color: "#2E7D32"},
      %{id: "CRU", nombre: "Cruz Andina",           codigo: "CRU", color: "#C62828"},
      %{id: "ANW", nombre: "Andes Wings",           codigo: "ANW", color: "#6A1B9A"}
    ]
  end

  # --- Vuelos ---

  defp insertar_vuelos do
    Enum.each(vuelos(), fn v ->
      vuelo =
        struct(Vuelo, Map.merge(v, %{
          asientos: crear_asientos(v.asientos_totales),
          reservas: %{},
          proxima_reserva_id: 1
        }))

      Persistencia.guardar(:vuelos, {:vuelo, vuelo.id}, vuelo)
    end)
  end

  defp vuelos do
    [
      # ARC – Aerolíneas del Cóndor
      %{id: "ARC-001", aerolinea_id: "ARC", origen: "EZE", destino: "COR", fecha: ~D[2026-01-10], hora: ~T[07:00:00], precio: 80_000, asientos_totales: 60},
      %{id: "ARC-002", aerolinea_id: "ARC", origen: "COR", destino: "EZE", fecha: ~D[2026-01-10], hora: ~T[10:30:00], precio: 80_000, asientos_totales: 60},
      %{id: "ARC-003", aerolinea_id: "ARC", origen: "EZE", destino: "MDZ", fecha: ~D[2026-02-14], hora: ~T[08:15:00], precio: 95_000, asientos_totales: 80},
      %{id: "ARC-004", aerolinea_id: "ARC", origen: "MDZ", destino: "EZE", fecha: ~D[2026-02-14], hora: ~T[13:00:00], precio: 95_000, asientos_totales: 80},
      %{id: "ARC-005", aerolinea_id: "ARC", origen: "AEP", destino: "BRC", fecha: ~D[2026-03-05], hora: ~T[09:00:00], precio: 120_000, asientos_totales: 50},
      %{id: "ARC-006", aerolinea_id: "ARC", origen: "BRC", destino: "AEP", fecha: ~D[2026-03-05], hora: ~T[14:30:00], precio: 120_000, asientos_totales: 50},
      %{id: "ARC-007", aerolinea_id: "ARC", origen: "EZE", destino: "IGR", fecha: ~D[2026-04-20], hora: ~T[06:45:00], precio: 110_000, asientos_totales: 70},
      %{id: "ARC-008", aerolinea_id: "ARC", origen: "IGR", destino: "EZE", fecha: ~D[2026-04-20], hora: ~T[12:00:00], precio: 110_000, asientos_totales: 70},
      %{id: "ARC-009", aerolinea_id: "ARC", origen: "AEP", destino: "SLA", fecha: ~D[2026-05-08], hora: ~T[11:00:00], precio: 105_000, asientos_totales: 40},
      %{id: "ARC-010", aerolinea_id: "ARC", origen: "SLA", destino: "AEP", fecha: ~D[2026-05-08], hora: ~T[16:00:00], precio: 105_000, asientos_totales: 40},

      # FLS – FlySur
      %{id: "FLS-001", aerolinea_id: "FLS", origen: "AEP", destino: "USH", fecha: ~D[2026-01-15], hora: ~T[06:00:00], precio: 180_000, asientos_totales: 40},
      %{id: "FLS-002", aerolinea_id: "FLS", origen: "USH", destino: "AEP", fecha: ~D[2026-01-15], hora: ~T[12:00:00], precio: 180_000, asientos_totales: 40},
      %{id: "FLS-003", aerolinea_id: "FLS", origen: "EZE", destino: "NQN", fecha: ~D[2026-02-22], hora: ~T[08:00:00], precio: 90_000,  asientos_totales: 55},
      %{id: "FLS-004", aerolinea_id: "FLS", origen: "NQN", destino: "EZE", fecha: ~D[2026-02-22], hora: ~T[13:30:00], precio: 90_000,  asientos_totales: 55},
      %{id: "FLS-005", aerolinea_id: "FLS", origen: "AEP", destino: "TUC", fecha: ~D[2026-03-18], hora: ~T[07:30:00], precio: 88_000,  asientos_totales: 65},
      %{id: "FLS-006", aerolinea_id: "FLS", origen: "TUC", destino: "AEP", fecha: ~D[2026-03-18], hora: ~T[13:00:00], precio: 88_000,  asientos_totales: 65},
      %{id: "FLS-007", aerolinea_id: "FLS", origen: "EZE", destino: "COR", fecha: ~D[2026-04-11], hora: ~T[10:00:00], precio: 82_000,  asientos_totales: 75},
      %{id: "FLS-008", aerolinea_id: "FLS", origen: "COR", destino: "EZE", fecha: ~D[2026-04-11], hora: ~T[15:30:00], precio: 82_000,  asientos_totales: 75},
      %{id: "FLS-009", aerolinea_id: "FLS", origen: "AEP", destino: "MDZ", fecha: ~D[2026-05-25], hora: ~T[09:15:00], precio: 97_000,  asientos_totales: 50},
      %{id: "FLS-010", aerolinea_id: "FLS", origen: "MDZ", destino: "AEP", fecha: ~D[2026-05-25], hora: ~T[14:45:00], precio: 97_000,  asientos_totales: 50},

      # PAM – Pampa Air
      %{id: "PAM-001", aerolinea_id: "PAM", origen: "COR", destino: "MDZ", fecha: ~D[2026-01-22], hora: ~T[08:30:00], precio: 70_000,  asientos_totales: 45},
      %{id: "PAM-002", aerolinea_id: "PAM", origen: "MDZ", destino: "COR", fecha: ~D[2026-01-22], hora: ~T[12:00:00], precio: 70_000,  asientos_totales: 45},
      %{id: "PAM-003", aerolinea_id: "PAM", origen: "EZE", destino: "BRC", fecha: ~D[2026-02-08], hora: ~T[07:00:00], precio: 115_000, asientos_totales: 60},
      %{id: "PAM-004", aerolinea_id: "PAM", origen: "BRC", destino: "EZE", fecha: ~D[2026-02-08], hora: ~T[13:00:00], precio: 115_000, asientos_totales: 60},
      %{id: "PAM-005", aerolinea_id: "PAM", origen: "AEP", destino: "IGR", fecha: ~D[2026-03-29], hora: ~T[08:00:00], precio: 108_000, asientos_totales: 55},
      %{id: "PAM-006", aerolinea_id: "PAM", origen: "IGR", destino: "AEP", fecha: ~D[2026-03-29], hora: ~T[14:00:00], precio: 108_000, asientos_totales: 55},
      %{id: "PAM-007", aerolinea_id: "PAM", origen: "EZE", destino: "SLA", fecha: ~D[2026-04-05], hora: ~T[09:30:00], precio: 103_000, asientos_totales: 40},
      %{id: "PAM-008", aerolinea_id: "PAM", origen: "SLA", destino: "EZE", fecha: ~D[2026-04-05], hora: ~T[15:00:00], precio: 103_000, asientos_totales: 40},
      %{id: "PAM-009", aerolinea_id: "PAM", origen: "AEP", destino: "NQN", fecha: ~D[2026-05-17], hora: ~T[10:00:00], precio: 88_000,  asientos_totales: 50},
      %{id: "PAM-010", aerolinea_id: "PAM", origen: "NQN", destino: "AEP", fecha: ~D[2026-05-17], hora: ~T[15:30:00], precio: 88_000,  asientos_totales: 50},

      # CRU – Cruz Andina
      %{id: "CRU-001", aerolinea_id: "CRU", origen: "MDZ", destino: "BRC", fecha: ~D[2026-01-30], hora: ~T[09:00:00], precio: 85_000,  asientos_totales: 35},
      %{id: "CRU-002", aerolinea_id: "CRU", origen: "BRC", destino: "MDZ", fecha: ~D[2026-01-30], hora: ~T[14:00:00], precio: 85_000,  asientos_totales: 35},
      %{id: "CRU-003", aerolinea_id: "CRU", origen: "EZE", destino: "USH", fecha: ~D[2026-02-18], hora: ~T[06:30:00], precio: 175_000, asientos_totales: 45},
      %{id: "CRU-004", aerolinea_id: "CRU", origen: "USH", destino: "EZE", fecha: ~D[2026-02-18], hora: ~T[13:00:00], precio: 175_000, asientos_totales: 45},
      %{id: "CRU-005", aerolinea_id: "CRU", origen: "AEP", destino: "COR", fecha: ~D[2026-03-12], hora: ~T[07:45:00], precio: 78_000,  asientos_totales: 70},
      %{id: "CRU-006", aerolinea_id: "CRU", origen: "COR", destino: "AEP", fecha: ~D[2026-03-12], hora: ~T[12:30:00], precio: 78_000,  asientos_totales: 70},
      %{id: "CRU-007", aerolinea_id: "CRU", origen: "EZE", destino: "TUC", fecha: ~D[2026-04-24], hora: ~T[08:00:00], precio: 92_000,  asientos_totales: 60},
      %{id: "CRU-008", aerolinea_id: "CRU", origen: "TUC", destino: "EZE", fecha: ~D[2026-04-24], hora: ~T[14:00:00], precio: 92_000,  asientos_totales: 60},
      %{id: "CRU-009", aerolinea_id: "CRU", origen: "AEP", destino: "IGR", fecha: ~D[2026-05-31], hora: ~T[09:30:00], precio: 112_000, asientos_totales: 50},
      %{id: "CRU-010", aerolinea_id: "CRU", origen: "IGR", destino: "AEP", fecha: ~D[2026-05-31], hora: ~T[15:00:00], precio: 112_000, asientos_totales: 50},

      # ANW – Andes Wings
      %{id: "ANW-001", aerolinea_id: "ANW", origen: "EZE", destino: "NQN", fecha: ~D[2026-01-08], hora: ~T[07:30:00], precio: 91_000,  asientos_totales: 55},
      %{id: "ANW-002", aerolinea_id: "ANW", origen: "NQN", destino: "EZE", fecha: ~D[2026-01-08], hora: ~T[13:00:00], precio: 91_000,  asientos_totales: 55},
      %{id: "ANW-003", aerolinea_id: "ANW", origen: "AEP", destino: "USH", fecha: ~D[2026-02-26], hora: ~T[06:15:00], precio: 182_000, asientos_totales: 40},
      %{id: "ANW-004", aerolinea_id: "ANW", origen: "USH", destino: "AEP", fecha: ~D[2026-02-26], hora: ~T[12:30:00], precio: 182_000, asientos_totales: 40},
      %{id: "ANW-005", aerolinea_id: "ANW", origen: "EZE", destino: "SLA", fecha: ~D[2026-03-22], hora: ~T[08:45:00], precio: 101_000, asientos_totales: 45},
      %{id: "ANW-006", aerolinea_id: "ANW", origen: "SLA", destino: "EZE", fecha: ~D[2026-03-22], hora: ~T[14:15:00], precio: 101_000, asientos_totales: 45},
      %{id: "ANW-007", aerolinea_id: "ANW", origen: "AEP", destino: "BRC", fecha: ~D[2026-04-15], hora: ~T[09:00:00], precio: 118_000, asientos_totales: 60},
      %{id: "ANW-008", aerolinea_id: "ANW", origen: "BRC", destino: "AEP", fecha: ~D[2026-04-15], hora: ~T[15:00:00], precio: 118_000, asientos_totales: 60},
      %{id: "ANW-009", aerolinea_id: "ANW", origen: "EZE", destino: "COR", fecha: ~D[2026-05-20], hora: ~T[10:30:00], precio: 81_000,  asientos_totales: 75},
      %{id: "ANW-010", aerolinea_id: "ANW", origen: "COR", destino: "EZE", fecha: ~D[2026-05-20], hora: ~T[16:00:00], precio: 81_000,  asientos_totales: 75}
    ]
  end

  defp crear_asientos(cantidad) do
    Enum.map(1..cantidad, fn numero ->
      %{
        numero: numero,
        estado: :libre
      }
    end)
  end
end
