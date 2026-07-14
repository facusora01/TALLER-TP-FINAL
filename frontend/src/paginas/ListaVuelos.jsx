import { useEffect, useMemo, useState } from 'react'
import { pedir, suscribir } from './../ws'

// TAL-10: listado de vuelos con filtro por fecha/destino y orden por precio.
export default function ListaVuelos() {
  const [vuelos, setVuelos] = useState(null)
  const [aerolineas, setAerolineas] = useState({})
  const [error, setError] = useState(null)

  const [fecha, setFecha] = useState('')
  const [destino, setDestino] = useState('')
  const [orden, setOrden] = useState('') // '', 'asc' o 'desc'

  const cargar = () => {
    pedir('listar_vuelos')
      .then((payload) => {
        setVuelos(payload.vuelos)
        setError(null)
      })
      .catch((e) => setError(e.mensaje || 'No se pudieron cargar los vuelos.'))
  }

  useEffect(() => {
    cargar()
    pedir('listar_aerolineas')
      .then((payload) => {
        const porId = {}
        payload.aerolineas.forEach((a) => {
          porId[a.id] = a
        })
        setAerolineas(porId)
      })
      .catch(() => {}) // sin nombres de aerolínea se muestra el código

    // Si cambia un asiento en cualquier vuelo, la disponibilidad puede cambiar.
    return suscribir((mensaje) => {
      if (mensaje.type === 'asiento_actualizado') {
        cargar()
      }
    })
  }, [])

  const destinos = useMemo(() => {
    if (!vuelos) return []
    return [...new Set(vuelos.map((v) => v.destino))].sort()
  }, [vuelos])

  const visibles = useMemo(() => {
    if (!vuelos) return []
    let resultado = vuelos.filter(
      (v) =>
        (!fecha || v.fecha === fecha) && (!destino || v.destino === destino)
    )
    if (orden === 'asc') {
      resultado = [...resultado].sort((a, b) => a.precio - b.precio)
    } else if (orden === 'desc') {
      resultado = [...resultado].sort((a, b) => b.precio - a.precio)
    }
    return resultado
  }, [vuelos, fecha, destino, orden])

  if (error) return <p className="error">{error}</p>
  if (!vuelos) return <p className="cargando">Cargando vuelos…</p>

  return (
    <section>
      <h2>Vuelos disponibles</h2>

      <div className="filtros">
        <label>
          Fecha
          <input
            type="date"
            value={fecha}
            onChange={(e) => setFecha(e.target.value)}
          />
        </label>
        <label>
          Destino
          <select value={destino} onChange={(e) => setDestino(e.target.value)}>
            <option value="">Todos</option>
            {destinos.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </label>
        <label>
          Precio
          <select value={orden} onChange={(e) => setOrden(e.target.value)}>
            <option value="">Sin ordenar</option>
            <option value="asc">Menor a mayor</option>
            <option value="desc">Mayor a menor</option>
          </select>
        </label>
        {(fecha || destino || orden) && (
          <button
            className="limpiar"
            onClick={() => {
              setFecha('')
              setDestino('')
              setOrden('')
            }}
          >
            Limpiar
          </button>
        )}
      </div>

      {visibles.length === 0 ? (
        <div className="vacio">
          <p className="vacio-titulo">No encontramos vuelos para esa búsqueda</p>
          <p>Probá con otra fecha u otro destino.</p>
        </div>
      ) : (
        <div className="grilla-vuelos">
          {visibles.map((v) => {
            const aerolinea = aerolineas[v.aerolinea_id]
            const color = aerolinea?.color || '#8b96ab'
            const agotado = v.asientos_disponibles === 0
            return (
              <article
                key={v.id}
                className="card-vuelo"
                style={{ '--color-aerolinea': color }}
              >
                <header className="card-aerolinea">
                  <span className="punto" style={{ background: color }} />
                  {aerolinea?.nombre || v.aerolinea_id}
                </header>

                <div className="card-ruta">
                  <div className="punta">
                    <span className="cod">{v.origen}</span>
                  </div>
                  <div className="linea-vuelo">
                    <span className="avion">✈</span>
                  </div>
                  <div className="punta">
                    <span className="cod">{v.destino}</span>
                  </div>
                </div>

                <div className="card-datos">
                  <span>{v.fecha}</span>
                  <span>{v.hora?.slice(0, 5)} hs</span>
                </div>

                <footer className="card-pie">
                  <div>
                    <span className="precio">
                      ${v.precio.toLocaleString('es-AR')}
                    </span>
                    <span
                      className={`disponibles ${agotado ? 'agotado' : ''}`}
                    >
                      {agotado
                        ? 'Sin asientos'
                        : `${v.asientos_disponibles} de ${v.asientos_totales} libres`}
                    </span>
                  </div>
                  <a className="boton" href={`#/vuelo/${v.id}`}>
                    Ver asientos
                  </a>
                </footer>
              </article>
            )
          })}
        </div>
      )}
    </section>
  )
}
