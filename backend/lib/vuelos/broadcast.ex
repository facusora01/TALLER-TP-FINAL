defmodule Vuelos.Broadcast do
  @moduledoc """
  Maneja las suscripciones y el envío de actualizaciones
  a todos los clientes que observan un vuelo.
  """

  @registry Vuelos.BroadcastRegistry

  def subscribir(vuelo_id, pid \\ self()) do
    Registry.register(@registry, vuelo_id, pid)
  end

  def notificar(vuelo) do
    Registry.dispatch(@registry, vuelo.id, fn entradas ->
      mensaje =
        Jason.encode!(%{
          type: "vuelo_actualizado",
          payload: %{
            vuelo_id: vuelo.id,
            asientos: vuelo.asientos
          }
        })

      Enum.each(entradas, fn {pid, _} ->
        send(pid, {:enviar, mensaje})
      end)
    end)
  end

  def notificar_reserva(vuelo, reserva) do
    Registry.dispatch(@registry, vuelo.id, fn entradas ->
      mensaje =
        Jason.encode!(%{
          type: "reserva_actualizada",
          payload: %{
            vuelo_id: vuelo.id,
            reserva_id: reserva.id,
            usuario_id: reserva.usuario.id,
            estado: reserva.estado
          }
        })

      Enum.each(entradas, fn {pid, _} ->
        send(pid, {:enviar, mensaje})
      end)
    end)
  end
end