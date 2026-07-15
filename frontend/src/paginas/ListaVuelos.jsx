import { useEffect, useMemo, useState } from 'react'
import { pedir } from './../ws'
import { ciudad, coincideDestino } from './../aeropuertos'

// TAL-10: listado de vuelos con filtros (fecha, destino, aerolínea) y orden por precio.
// Sin orden elegido, los vuelos van del más próximo al más lejano en fecha.
export default function ListaVuelos() {
  const [vuelos, setVuelos] = useState(null)
  const [aerolineas, setAerolineas] = useState({})
  const [error, setError] = useState(null)

  const [fecha, setFecha] = useState('')
  const [destino, setDestino] = useState('') // texto libre: ciudad o código
  const [aerolinea, setAerolinea] = useState('')
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

    // El listado no se suscribe a un vuelo puntual (el broadcast es por vuelo);
    // la disponibilidad se refresca al volver a entrar a esta vista.
  }, [])

  const destinos = useMemo(() => {
    if (!vuelos) return []
    return [...new Set(vuelos.map((v) => v.destino))].sort()
  }, [vuelos])

  const visibles = useMemo(() => {
    if (!vuelos) return []
    const resultado = vuelos.filter(
      (v) =>
        (!fecha || v.fecha === fecha) &&
        (!aerolinea || v.aerolinea_id === aerolinea) &&
        coincideDestino(v.destino, destino)
    )
    if (orden === 'asc') {
      return [...resultado].sort((a, b) => a.precio - b.precio)
    }
    if (orden === 'desc') {
      return [...resultado].sort((a, b) => b.precio - a.precio)
    }
    // Por defecto: del vuelo más cercano al más lejano (fecha ISO ordena bien).
    return [...resultado].sort((a, b) =>
      `${a.fecha} ${a.hora}`.localeCompare(`${b.fecha} ${b.hora}`)
    )
  }, [vuelos, fecha, destino, aerolinea, orden])

  if (error) return <p className="error">{error}</p>
  if (!vuelos) return <p className="cargando">Cargando vuelos…</p>

  const hayFiltros = fecha || destino || aerolinea || orden

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
          <input
            type="text"
            list="lista-destinos"
            placeholder="Ciudad o código"
            value={destino}
            onChange={(e) => setDestino(e.target.value)}
          />
          <datalist id="lista-destinos">
            {destinos.map((d) => (
              <option key={d} value={ciudad(d)}>
                {d}
              </option>
            ))}
          </datalist>
        </label>
        <label>
          Aerolínea
          <select
            value={aerolinea}
            onChange={(e) => setAerolinea(e.target.value)}
          >
            <option value="">Todas</option>
            {Object.values(aerolineas).map((a) => (
              <option key={a.id} value={a.id}>
                {a.nombre}
              </option>
            ))}
          </select>
        </label>
        <label>
          Precio
          <select value={orden} onChange={(e) => setOrden(e.target.value)}>
            <option value="">Fecha más próxima</option>
            <option value="asc">Menor a mayor</option>
            <option value="desc">Mayor a menor</option>
          </select>
        </label>
        {hayFiltros && (
          <button
            className="limpiar"
            onClick={() => {
              setFecha('')
              setDestino('')
              setAerolinea('')
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
          <p>Probá con otra fecha, destino o aerolínea.</p>
        </div>
      ) : (
        <div className="grilla-vuelos">
          {visibles.map((v) => {
            const info = aerolineas[v.aerolinea_id]
            const color = info?.color || '#8b96ab'
            const agotado = v.asientos_disponibles === 0
            return (
              <article
                key={v.id}
                className="card-vuelo"
                style={{ '--color-aerolinea': color }}
              >
                <header className="card-aerolinea">
                  <span className="punto" style={{ background: color }} />
                  {info?.nombre || v.aerolinea_id}
                </header>

                <div className="card-ruta">
                  <div className="punta">
                    <span className="cod">{v.origen}</span>
                    <span className="ciudad">{ciudad(v.origen)}</span>
                  </div>
                  <div className="linea-vuelo">
                    <span className="avion">✈</span>
                  </div>
                  <div className="punta derecha">
                    <span className="cod">{v.destino}</span>
                    <span className="ciudad">{ciudad(v.destino)}</span>
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
