// Cliente WebSocket único para hablar con el backend (ver docs/NOTAS/M1/protocoloMensajes.md).
// Expone `pedir` (request/response por request_id) y `suscribir` (eventos push del servidor).

const URL_WS =
  import.meta.env.VITE_WS_URL || `ws://${window.location.hostname}:4000/ws`

const TIMEOUT_MS = 8000
const REINTENTO_MS = 1500

let socket = null
let proximoId = 1
const pendientes = new Map() // request_id -> {resolver, rechazar, timer}
const oyentes = new Set() // callbacks para eventos push
const colaSalida = [] // mensajes encolados mientras no hay conexión

function conectar() {
  socket = new WebSocket(URL_WS)

  socket.onopen = () => {
    while (colaSalida.length > 0) {
      socket.send(colaSalida.shift())
    }
    avisar({ type: 'conexion', payload: { conectado: true } })
  }

  socket.onmessage = (evento) => {
    let mensaje
    try {
      mensaje = JSON.parse(evento.data)
    } catch {
      return
    }

    const pendiente = mensaje.request_id && pendientes.get(mensaje.request_id)
    if (pendiente) {
      pendientes.delete(mensaje.request_id)
      clearTimeout(pendiente.timer)
      if (mensaje.type === 'error') {
        pendiente.rechazar(mensaje.payload)
      } else {
        pendiente.resolver(mensaje.payload)
      }
      return
    }

    // Sin request_id conocido: es un evento push del servidor.
    avisar(mensaje)
  }

  socket.onclose = () => {
    avisar({ type: 'conexion', payload: { conectado: false } })
    setTimeout(conectar, REINTENTO_MS)
  }

  socket.onerror = () => {
    socket.close()
  }
}

function avisar(mensaje) {
  oyentes.forEach((oyente) => oyente(mensaje))
}

/** Envía un mensaje al servidor y devuelve una promesa con el payload de la respuesta. */
export function pedir(type, payload = {}) {
  const request_id = String(proximoId++)
  const texto = JSON.stringify({ type, request_id, payload })

  return new Promise((resolver, rechazar) => {
    const timer = setTimeout(() => {
      pendientes.delete(request_id)
      rechazar({ codigo: 'TIMEOUT', mensaje: 'El servidor no respondió.' })
    }, TIMEOUT_MS)

    pendientes.set(request_id, { resolver, rechazar, timer })

    if (socket && socket.readyState === WebSocket.OPEN) {
      socket.send(texto)
    } else {
      colaSalida.push(texto)
    }
  })
}

/** Registra un callback para todos los mensajes push; devuelve la función para desuscribirse. */
export function suscribir(oyente) {
  oyentes.add(oyente)
  return () => oyentes.delete(oyente)
}

conectar()
