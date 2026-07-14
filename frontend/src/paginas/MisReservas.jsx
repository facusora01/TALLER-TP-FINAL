import { useEffect, useState } from 'react'
import { pedir, suscribir } from './../ws'

const ETIQUETAS = {
  pendiente: 'Pendiente',
  confirmada: 'Confirmada',
  cancelada: 'Cancelada',
  expirada: 'Expirada',
}

// TAL-7: reservas del usuario con estado actual y cancelación de pendientes.
export default function MisReservas({ usuario }) {
  const [reservas, setReservas] = useState(null)
  const [error, setError] = useState(null)
  const [ocupada, setOcupada] = useState(null) // reserva_id con acción en curso

  const cargar = () => {
    pedir('mis_reservas', { usuario_id: usuario.id })
      .then((payload) => {
        setReservas(payload.reservas)
        setError(null)
      })
      .catch((e) =>
        setError(e.mensaje || 'No se pudieron cargar las reservas.')
      )
  }

  useEffect(() => {
    cargar()

    // Push del servidor cuando una reserva cambia de estado (confirmada/expirada/etc.).
    return suscribir((mensaje) => {
      if (
        mensaje.type === 'reserva_actualizada' ||
        mensaje.type === 'asiento_actualizado'
      ) {
        cargar()
      }
    })
  }, [usuario.id]) // eslint-disable-line react-hooks/exhaustive-deps

  const operar = async (tipo, reserva, mensajeError) => {
    setOcupada(reserva.reserva_id)
    setError(null)
    try {
      await pedir(tipo, {
        vuelo_id: reserva.vuelo_id,
        reserva_id: reserva.reserva_id,
      })
    } catch (e) {
      setError(e.mensaje || mensajeError)
    } finally {
      setOcupada(null)
      cargar()
    }
  }

  const confirmar = (reserva) =>
    operar('confirmar_reserva', reserva, 'No se pudo confirmar la reserva.')
  const cancelar = (reserva) =>
    operar('cancelar_reserva', reserva, 'No se pudo cancelar la reserva.')

  if (error && !reservas) return <p className="error">{error}</p>
  if (!reservas) return <p className="cargando">Cargando reservas…</p>

  return (
    <section>
      <h2>Mis reservas</h2>

      {error && <p className="error">{error}</p>}

      {reservas.length === 0 ? (
        <div className="vacio">
          <p>Todavía no tenés reservas.</p>
          <a className="boton" href="#/">
            Buscar vuelos
          </a>
        </div>
      ) : (
        <table className="tabla-reservas">
          <thead>
            <tr>
              <th>Reserva</th>
              <th>Vuelo</th>
              <th>Trayecto</th>
              <th>Fecha</th>
              <th>Asiento</th>
              <th>Estado</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {reservas.map((r) => (
              <tr key={`${r.vuelo_id}-${r.reserva_id}`}>
                <td>#{r.reserva_id}</td>
                <td>
                  <a href={`#/vuelo/${r.vuelo_id}`}>{r.vuelo_id}</a>
                </td>
                <td>
                  {r.origen} → {r.destino}
                </td>
                <td>
                  {r.fecha} {r.hora?.slice(0, 5)}
                </td>
                <td>{r.numero_asiento}</td>
                <td>
                  <span className={`estado ${r.estado}`}>
                    {ETIQUETAS[r.estado] || r.estado}
                  </span>
                </td>
                <td>
                  {r.estado === 'pendiente' && (
                    <div className="acciones">
                      <button
                        className="confirmar"
                        disabled={ocupada !== null}
                        onClick={() => confirmar(r)}
                      >
                        {ocupada === r.reserva_id ? '…' : 'Confirmar'}
                      </button>
                      <button
                        className="peligro"
                        disabled={ocupada !== null}
                        onClick={() => cancelar(r)}
                      >
                        Cancelar
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
