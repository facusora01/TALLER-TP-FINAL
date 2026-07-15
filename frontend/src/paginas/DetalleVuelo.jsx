import { useEffect, useState } from 'react'
import { pedir, suscribir } from './../ws'

const LETRAS = 'ABCDEFGHJK' // sin "I", como en los aviones reales

// Clases de asiento: nombre visible y multiplicador sobre el precio base.
const CLASES = {
  first: { nombre: 'First Class', multiplicador: 2.5 },
  business: { nombre: 'Business', multiplicador: 1.5 },
  economy: { nombre: 'Economy', multiplicador: 1 },
}

function infoClase(clase) {
  return CLASES[clase] || CLASES.economy
}

function precioAsiento(vuelo, asiento) {
  return Math.round(vuelo.precio * infoClase(asiento.clase).multiplicador)
}

// Etiqueta del asiento (fila + letra) según cuántos asientos hay por fila.
function etiquetaAsiento(numero, porFila) {
  const fila = Math.floor((numero - 1) / porFila) + 1
  const letra = LETRAS[(numero - 1) % porFila]
  return `${fila}${letra}`
}

// Agrupa los asientos en filas según la distribución del avión.
function agruparEnFilas(asientos, porFila) {
  const filas = []
  for (let i = 0; i < asientos.length; i += porFila) {
    filas.push(asientos.slice(i, i + porFila))
  }
  return filas
}

// Corta una fila en grupos de columnas separados por pasillos (ej: [2,4,2]).
function cortarEnGrupos(fila, distribucion) {
  const grupos = []
  let desde = 0
  distribucion.forEach((cantidad) => {
    grupos.push(fila.slice(desde, desde + cantidad))
    desde += cantidad
  })
  return grupos
}

// TAL-9 / TAL-32: detalle de un vuelo con mapa de asientos por clase, en tiempo real.
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

  const reservar = async (asiento, porFila) => {
    if (asiento.estado !== 'libre' || reservando) return
    setReservando(asiento.numero)
    setAviso(null)
    try {
      const payload = await pedir('reservar_asiento', {
        vuelo_id: vueloId,
        numero_asiento: asiento.numero,
        usuario_id: usuario.id,
      })
      setAviso({
        tipo: 'ok',
        texto: `Reserva #${payload.reserva_id} creada: asiento ${etiquetaAsiento(
          asiento.numero,
          porFila
        )} (${infoClase(asiento.clase).nombre}, $${precioAsiento(
          vuelo,
          asiento
        ).toLocaleString('es-AR')}). Confirmala desde "Mis reservas" antes de que expire.`,
      })
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

  const distribucion = vuelo.distribucion || [3, 3]
  const porFila = distribucion.reduce((a, b) => a + b, 0)
  const libres = asientos.filter((a) => a.estado === 'libre').length
  const filas = agruparEnFilas(asientos, porFila)

  const botonAsiento = (asiento) => (
    <button
      key={asiento.numero}
      className={`asiento ${asiento.estado} clase-${asiento.clase || 'economy'}`}
      disabled={asiento.estado !== 'libre' || reservando !== null}
      title={`${etiquetaAsiento(asiento.numero, porFila)} · ${
        infoClase(asiento.clase).nombre
      } · $${precioAsiento(vuelo, asiento).toLocaleString('es-AR')} (${asiento.estado})`}
      onClick={() => reservar(asiento, porFila)}
    >
      {reservando === asiento.numero
        ? '…'
        : etiquetaAsiento(asiento.numero, porFila)}
    </button>
  )

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
            <dt>Avión</dt>
            <dd>{vuelo.avion || '—'}</dd>
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
            <dt>Precio desde</dt>
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

      <div className="leyenda clases">
        {Object.entries(CLASES).map(([clave, c]) => (
          <span key={clave}>
            <i className={`asiento libre clase-${clave}`} /> {c.nombre} · $
            {Math.round(vuelo.precio * c.multiplicador).toLocaleString('es-AR')}
          </span>
        ))}
      </div>

      <div className="cabina">
        <div className="filas">
          {filas.map((fila, i) => {
            const clase = fila[0]?.clase || 'economy'
            const clasePrevia = i > 0 ? filas[i - 1][0]?.clase : null
            return (
              <div key={i}>
                {clase !== clasePrevia && (
                  <div className={`seccion-clase clase-${clase}`}>
                    {infoClase(clase).nombre}
                  </div>
                )}
                <div className="fila">
                  <span className="num-fila">{i + 1}</span>
                  {cortarEnGrupos(fila, distribucion).map((grupo, g) => (
                    <div className="grupo-con-pasillo" key={g}>
                      {g > 0 && <div className="pasillo" />}
                      <div className="grupo">{grupo.map(botonAsiento)}</div>
                    </div>
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
