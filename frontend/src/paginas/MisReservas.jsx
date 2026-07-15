import { useEffect, useState } from 'react'
import { pedir, suscribir } from './../ws'

const ETIQUETAS = {
  pendiente: 'Pendiente',
  confirmada: 'Confirmada',
  cancelada: 'Cancelada',
  expirada: 'Expirada',
}

const NOMBRES_CLASE = {
  first: 'First Class',
  business: 'Business',
  economy: 'Economy',
}

// TAL-7: reservas del usuario con estado actual y cancelación de pendientes.
export default function MisReservas({ usuario }) {
  const [reservas, setReservas] = useState(null)
  const [tiempos, setTiempos] = useState({})
  const [error, setError] = useState(null)
  const [ocupada, setOcupada] = useState(null) // reserva_id con acción en curso
  const [aviso, setAviso] = useState(null)

  const cargar = () => {
    return pedir('mis_reservas', { usuario_id: usuario.id })
      .then((payload) => {
        setReservas(payload.reservas)
  
        const nuevosTiempos = {}
  
        payload.reservas.forEach((r) => {
          if (r.estado === 'pendiente') {
            nuevosTiempos[r.reserva_id] =
              r.segundos_restantes
          }
        })
  
        setTiempos(nuevosTiempos)
  
        setError(null)
        return payload.reservas
      })
      .catch((e) => {
        setError(e.mensaje || 'No se pudieron cargar las reservas.')
        return []
      })
  }

  useEffect(() => {
    // El broadcast es por vuelo: nos suscribimos a cada vuelo donde el usuario
    // tiene reservas, y ante cualquier cambio recargamos su listado.
    const desuscribir = suscribir((mensaje) => {
      if (mensaje.type === 'vuelo_actualizado') {
        cargar()
        return
      }
    
      if (mensaje.type === 'reserva_actualizada') {
        cargar()
    
        const { estado, reserva_id } = mensaje.payload
    
        if (estado === 'confirmada') {
          setAviso({
            tipo: 'ok',
            texto: `La reserva #${reserva_id} fue confirmada correctamente.`,
          })
        }
    
        if (estado === 'expirada') {
          setAviso({
            tipo: 'error',
            texto: `La reserva #${reserva_id} expiró porque no fue confirmada a tiempo.`,
          })
        }
    
        if (estado === 'cancelada') {
          setAviso({
            tipo: 'ok',
            texto: `La reserva #${reserva_id} fue cancelada.`,
          })
        }
      }
    })

    cargar().then((reservas) => {
      const vuelos = [...new Set((reservas || []).map((r) => r.vuelo_id))]
      vuelos.forEach((id) =>
        pedir('suscribir_vuelo', { vuelo_id: id }).catch(() => {})
      )
    })

    return desuscribir
  }, [usuario.id]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    const id = setInterval(() => {
      setTiempos((prev) => {
        const actualizado = {}
  
        Object.entries(prev).forEach(([id, segundos]) => {
          actualizado[id] = Math.max(segundos - 1, 0)
        })
  
        return actualizado
      })
    }, 1000)
  
    return () => clearInterval(id)
  }, [])

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

  const confirmar = (reserva) => {
    window.location.hash = `#/pago/${reserva.vuelo_id}/${reserva.reserva_id}`
  }
  const cancelar = (reserva) =>
    operar('cancelar_reserva', reserva, 'No se pudo cancelar la reserva.')

  if (error && !reservas) return <p className="error">{error}</p>
  if (!reservas) return <p className="cargando">Cargando reservas…</p>

  return (
    <section>
      <h2>Mis reservas</h2>

      {aviso && (
        <div className={`aviso ${aviso.tipo}`}>
          {aviso.texto}
        </div>
      )}

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
              <th>Clase</th>
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
                <td>{NOMBRES_CLASE[r.clase] || '—'}</td>
                <td>
                  <span className={`estado ${r.estado}`}>
                    {ETIQUETAS[r.estado] || r.estado}
                  </span>

                  {r.estado === 'pendiente' && (
                    <div>
                      ⏳ {String(
                        Math.floor(
                          (tiempos[r.reserva_id] ?? r.segundos_restantes) / 60
                        )
                      ).padStart(2, '0')}
                      :
                      {String(
                        (tiempos[r.reserva_id] ?? r.segundos_restantes) % 60
                      ).padStart(2, '0')}
                    </div>
                  )}
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
