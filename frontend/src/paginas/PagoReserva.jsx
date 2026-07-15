import { useEffect, useState } from 'react'
import { pedir, suscribir } from './../ws'

export default function PagoReserva({ vueloId, reservaId, usuario }) {
  const [segundos, setSegundos] = useState(60)
  const [estado, setEstado] = useState('pendiente')

  const [vuelo, setVuelo] = useState(null)
  const [reserva, setReserva] = useState(null)

  useEffect(() => {
    pedir('buscar_vuelo', {
      vuelo_id: vueloId,
    })
      .then(setVuelo)
      .catch(() => {})

    pedir('mis_reservas', {
      usuario_id: usuario.id,
    })
      .then((payload) => {
        const encontrada = payload.reservas.find(
          (r) =>
            r.vuelo_id === vueloId &&
            r.reserva_id === reservaId
        )

        if (encontrada) {
          setReserva(encontrada)
        }
      })
      .catch(() => {})
  }, [vueloId, reservaId, usuario.id])

  useEffect(() => {
    pedir('suscribir_vuelo', {
      vuelo_id: vueloId,
    }).catch(() => {})

    const desuscribir = suscribir((mensaje) => {
      if (mensaje.type !== 'reserva_actualizada') return

      const payload = mensaje.payload

      if (
        payload.vuelo_id === vueloId &&
        payload.reserva_id === reservaId
      ) {
        setEstado(payload.estado)
      }
    })

    return desuscribir
  }, [vueloId, reservaId])

  useEffect(() => {
    if (estado !== 'pendiente') return

    const id = setInterval(() => {
      setSegundos((s) => Math.max(0, s - 1))
    }, 1000)

    return () => clearInterval(id)
  }, [estado])

  const cancelar = async () => {
    try {
      await pedir('cancelar_reserva', {
        vuelo_id: vueloId,
        reserva_id: reservaId,
      })
    } catch {}
  }

  const minutos = String(Math.floor(segundos / 60)).padStart(2, '0')
  const segundosTexto = String(segundos % 60).padStart(2, '0')
  const porcentaje = (segundos / 60) * 100

  return (
    <section className="pantalla-pago">

      <h2>Procesando pago</h2>

      <div className="reserva-numero">
        Reserva #{reservaId}
      </div>

      {vuelo && (
        <div className="resumen-vuelo">

          <div className="resumen-ruta">
            <strong>
              {vuelo.origen} → {vuelo.destino}
            </strong>
          </div>

          <div className="resumen-datos">
            <span>📅 {vuelo.fecha}</span>

            <span>🕓 {vuelo.hora?.slice(0, 5)}</span>

            {reserva && (
              <span>
                💺 Asiento {reserva.numero_asiento}
              </span>
            )}
          </div>

        </div>
      )}

      {estado === 'pendiente' && (
        <>

          <div className="spinner" />

          <p className="texto-proceso">
            Estamos procesando el pago de tu reserva.
          </p>

          <p className="texto-secundario">
            La confirmación suele demorar entre 1 y 5 segundos.
          </p>

          <h1 className={segundos <= 15 ? 'contador alerta' : 'contador'}>
            {minutos}:{segundosTexto}
          </h1>

          <div className="barra-tiempo">
            <div
              style={{
                width: `${porcentaje}%`,
              }}
            />
          </div>

          <button
            className="peligro"
            onClick={cancelar}
          >
            Cancelar reserva
          </button>

        </>
      )}

      {estado === 'confirmada' && (
        <>

          <div className="estado-icono estado-ok">
            ✅
          </div>

          <h1 style={{color: 'black'}}>Pago aprobado</h1>

          <p>
            Tu reserva fue confirmada correctamente.
          </p>

          <a
            className="boton"
            href="#/reservas"
          >
            Ir a mis reservas
          </a>

        </>
      )}

      {estado === 'cancelada' && (
        <>

          <div className="estado-icono estado-error">
            ❌
          </div>

          <h1 style={{color: 'black'}}>Reserva cancelada</h1>

          <p>
            La reserva fue cancelada correctamente.
          </p>

          <a
            className="boton"
            href="#/"
          >
            Buscar otro vuelo
          </a>

        </>
      )}

      {estado === 'expirada' && (
        <>

          <div className="estado-icono estado-expirado">
            ⌛
          </div>

          <h1>Tiempo agotado</h1>

          <p>
            La reserva expiró antes de que el pago pudiera completarse.
          </p>

          <a
            className="boton"
            href={`#/vuelo/${vueloId}`}
          >
            Volver al vuelo
          </a>

        </>
      )}

    </section>
  )
}