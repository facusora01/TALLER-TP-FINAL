import { useEffect, useState } from 'react'
import { pedir, suscribir } from './../ws'

const COLUMNAS = ['A', 'B', 'C', 'D', 'E', 'F']
const POR_FILA = 6

// Etiqueta realista del asiento (fila + letra) a partir de su número global.
function etiquetaAsiento(numero) {
  const fila = Math.floor((numero - 1) / POR_FILA) + 1
  const letra = COLUMNAS[(numero - 1) % POR_FILA]
  return `${fila}${letra}`
}

// Agrupa los asientos en filas de a POR_FILA para dibujar la cabina.
function agruparEnFilas(asientos) {
  const filas = []
  for (let i = 0; i < asientos.length; i += POR_FILA) {
    filas.push(asientos.slice(i, i + POR_FILA))
  }
  return filas
}

// TAL-9: detalle de un vuelo con mapa de asientos en tiempo real.
export default function DetalleVuelo({ vueloId, usuario }) {
  const [vuelo, setVuelo] = useState(null)
  const [asientos, setAsientos] = useState(null)
  const [error, setError] = useState(null)
  const [reservando, setReservando] = useState(null) // número de asiento en curso
  const [aviso, setAviso] = useState(null) // {tipo: 'ok'|'error', texto}

  const cargarAsientos = () => {
    pedir('obtener_asientos', { vuelo_id: vueloId })
      .then((payload) => setAsientos(payload.asientos))
      .catch((e) => setError(e.mensaje || 'No se pudo cargar el vuelo.'))
  }

  useEffect(() => {
    pedir('buscar_vuelo', { vuelo_id: vueloId })
      .then(setVuelo)
      .catch((e) => setError(e.mensaje || 'No se pudo cargar el vuelo.'))
    cargarAsientos()

    // Nos suscribimos al vuelo para recibir sus cambios de asientos en vivo.
    pedir('suscribir_vuelo', { vuelo_id: vueloId }).catch(() => {})

    // El servidor emite `vuelo_actualizado` con la lista completa de asientos.
    return suscribir((mensaje) => {
      if (
        mensaje.type === 'vuelo_actualizado' &&
        mensaje.payload.vuelo_id === vueloId
      ) {
        setAsientos(mensaje.payload.asientos)
      }
    })
  }, [vueloId]) // eslint-disable-line react-hooks/exhaustive-deps

  const reservar = async (asiento) => {
    if (asiento.estado !== 'libre' || reservando) return
    setReservando(asiento.numero)
    setAviso(null)
    try {
      const payload = await pedir('reservar_asiento', {
        vuelo_id: vueloId,
        numero_asiento: asiento.numero,
        usuario_id: usuario.id,
      })
      window.location.hash =`#/pago/${vueloId}/${payload.reserva_id}`
    } catch (e) {
      setAviso({
        tipo: 'error',
        texto: e.mensaje || 'No se pudo reservar el asiento.',
      })
    } finally {
      setReservando(null)
      cargarAsientos()
    }
  }

  // Vuelo inexistente o error de carga: mensaje claro y salida al listado.
  if (error)
    return (
      <section>
        <a href="#/" className="volver">
          ← Volver al listado
        </a>
        <div className="aviso error">{error}</div>
      </section>
    )
  if (!vuelo || !asientos) return <p className="cargando">Cargando vuelo…</p>

  const libres = asientos.filter((a) => a.estado === 'libre').length

  return (
    <section>
      <a href="#/" className="volver">
        ← Volver al listado
      </a>

      <div className="ficha-vuelo">
        <h2>
          {vuelo.origen} → {vuelo.destino}
        </h2>
        <dl>
          <div>
            <dt>Aerolínea</dt>
            <dd>{vuelo.aerolinea_id}</dd>
          </div>
          <div>
            <dt>Fecha</dt>
            <dd>{vuelo.fecha}</dd>
          </div>
          <div>
            <dt>Hora</dt>
            <dd>{vuelo.hora?.slice(0, 5)}</dd>
          </div>
          <div>
            <dt>Precio</dt>
            <dd>${vuelo.precio.toLocaleString('es-AR')}</dd>
          </div>
          <div>
            <dt>Disponibles</dt>
            <dd>
              {libres} / {vuelo.asientos_totales}
            </dd>
          </div>
        </dl>
      </div>

      {aviso && (
        <div className={`aviso ${aviso.tipo}`}>
          {aviso.texto}
          {aviso.tipo === 'ok' && <a href="#/reservas"> Ver mis reservas</a>}
        </div>
      )}

      {libres === 0 && (
        <div className="aviso error">
          Este vuelo no tiene asientos disponibles.
        </div>
      )}

      <div className="leyenda">
        <span>
          <i className="asiento libre" /> Disponible
        </span>
        <span>
          <i className="asiento reservado" /> Reservado
        </span>
        <span>
          <i className="asiento confirmado" /> Confirmado
        </span>
      </div>

      <div className="cabina">
        <div className="filas">
          {agruparEnFilas(asientos).map((fila, i) => (
            <div className="fila" key={i}>
              <span className="num-fila">{i + 1}</span>
              <div className="grupo">
                {fila.slice(0, 3).map((asiento) => (
                  <button
                    key={asiento.numero}
                    className={`asiento ${asiento.estado}`}
                    disabled={asiento.estado !== 'libre' || reservando !== null}
                    title={`Asiento ${etiquetaAsiento(asiento.numero)} (${asiento.estado})`}
                    onClick={() => reservar(asiento)}
                  >
                    {reservando === asiento.numero
                      ? '…'
                      : etiquetaAsiento(asiento.numero)}
                  </button>
                ))}
              </div>
              <div className="pasillo" />
              <div className="grupo">
                {fila.slice(3, 6).map((asiento) => (
                  <button
                    key={asiento.numero}
                    className={`asiento ${asiento.estado}`}
                    disabled={asiento.estado !== 'libre' || reservando !== null}
                    title={`Asiento ${etiquetaAsiento(asiento.numero)} (${asiento.estado})`}
                    onClick={() => reservar(asiento)}
                  >
                    {reservando === asiento.numero
                      ? '…'
                      : etiquetaAsiento(asiento.numero)}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
