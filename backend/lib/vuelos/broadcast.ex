defmodule Vuelos.Broadcast do
  @moduledoc """
  Maneja las suscripciones y el envío de actualizaciones
  a todos los clientes que observan un vuelo.
  """

  @registry Vuelos.BroadcastRegistry

  # PRE: recibe el id del vuelo y el pid de la conexion; el BroadcastRegistry esta corriendo.
  # POST: registra el pid como suscriptor del vuelo; recibira los push de ese vuelo.
  def subscribir(vuelo_id, pid \\ self()) do
    Registry.register(@registry, vuelo_id, pid)
  end

  # PRE: recibe el vuelo (con id y asientos).
  # POST: manda "vuelo_actualizado" con los asientos a todos los suscriptos al vuelo.
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

  # PRE: recibe el vuelo y una reserva que le pertenece.
  # POST: manda "reserva_actualizada" con el nuevo estado a todos los suscriptos al vuelo.
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