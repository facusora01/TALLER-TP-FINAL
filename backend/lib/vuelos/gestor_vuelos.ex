defmodule Vuelos.GestorVuelos do
  @moduledoc """
  API para acceder a los vuelos del sistema.

  Los ServidorVuelo se crean bajo demanda.
  """

  alias Vuelos.{Persistencia, ServidorVuelo}

  @tabla :vuelos

  def listar_vuelos do
    Persistencia.todos(@tabla)
    |> Enum.flat_map(fn
      {{:vuelo, _}, vuelo} -> [vuelo]
      _ -> []
    end)
  end

  def buscar_vuelo(id) do
    case Persistencia.obtener(@tabla, {:vuelo, id}) do
      {:ok, vuelo} -> vuelo
      :error -> nil
    end
  end

  def buscar_por_destino(destino) do
    listar_vuelos()
    |> Enum.filter(fn vuelo ->
      vuelo.destino == destino
    end)
  end

  def buscar_por_fecha(fecha) do
    listar_vuelos()
    |> Enum.filter(fn vuelo ->
      vuelo.fecha == fecha
    end)
  end

  def obtener_estado(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_estado(id)}
    end
  end

  def obtener_asientos(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_asientos(id)}
    end
  end

  def obtener_reservas(id) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      {:ok, ServidorVuelo.obtener_reservas(id)}
    end
  end

  def reservar_asiento(id, numero_asiento, usuario) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.reservar_asiento(id, numero_asiento, usuario)
    end
  end

  def confirmar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.confirmar_reserva(id, id_reserva)
    end
  end

  def cancelar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.cancelar_reserva(id, id_reserva)
    end
  end

  def expirar_reserva(id, id_reserva) do
    with {:ok, _pid} <- asegurar_servidor(id) do
      ServidorVuelo.expirar_reserva(id, id_reserva)
    end
  end

  defp asegurar_servidor(id) do
    case Registry.lookup(Vuelos.Registro, id) do
      [{pid, _}] ->
        if Process.alive?(pid) do
          {:ok, pid}
        else
          reiniciar_servidor(id)
        end

      [] ->
        reiniciar_servidor(id)
    end
  end

  defp reiniciar_servidor(id) do
    case Persistencia.obtener(@tabla, {:vuelo, id}) do
      {:ok, vuelo} ->
        case DynamicSupervisor.start_child(
              Vuelos.SupervisorVuelos,
              {ServidorVuelo, vuelo}
            ) do
          {:ok, pid} ->
            {:ok, pid}

          {:error, {:already_started, pid}} ->
            {:ok, pid}

          otro ->
            otro
        end

      :error ->
        :error
    end
  end
end