import { useEffect, useState } from 'react'
import { suscribir } from './ws'
import { usuarioGuardado, iniciarSesion, validar, cerrarSesion } from './usuario'
import ListaVuelos from './paginas/ListaVuelos'
import DetalleVuelo from './paginas/DetalleVuelo'
import MisReservas from './paginas/MisReservas'
import './App.css'

// Logo: aguja de brújula estilizada (guiño a "Nomad").
function Logo() {
  return (
    <svg className="logo" viewBox="0 0 32 32" aria-hidden="true">
      <circle cx="16" cy="16" r="15" className="logo-anillo" />
      <path d="M16 5 L21 20 L16 16 L11 20 Z" className="logo-aguja" />
      <circle cx="16" cy="16" r="1.8" className="logo-centro" />
    </svg>
  )
}

// Router mínimo por hash: "#/", "#/vuelo/<id>", "#/reservas".
function useRuta() {
  const [hash, setHash] = useState(window.location.hash)

  useEffect(() => {
    const alCambiar = () => setHash(window.location.hash)
    window.addEventListener('hashchange', alCambiar)
    return () => window.removeEventListener('hashchange', alCambiar)
  }, [])

  const partes = hash.replace(/^#\/?/, '').split('/')
  if (partes[0] === 'vuelo' && partes[1]) {
    return { pagina: 'vuelo', vueloId: decodeURIComponent(partes[1]) }
  }
  if (partes[0] === 'reservas') {
    return { pagina: 'reservas' }
  }
  return { pagina: 'vuelos' }
}

function FormularioRegistro({ alRegistrar }) {
  const [nombre, setNombre] = useState('')
  const [error, setError] = useState(null)
  const [enviando, setEnviando] = useState(false)

  const enviar = async (evento) => {
    evento.preventDefault()
    if (!nombre.trim()) return
    setEnviando(true)
    setError(null)
    try {
      alRegistrar(await iniciarSesion(nombre.trim()))
    } catch (e) {
      setError(e.mensaje || 'No se pudo iniciar sesión.')
      setEnviando(false)
    }
  }

  return (
    <div className="registro">
      <div className="registro-marca">
        <Logo />
        <span>
          Nomad<strong>Air</strong>
        </span>
      </div>
      <h1>Tu próximo vuelo, listo para despegar</h1>
      <p>Ingresá tu nombre para entrar. Si ya lo usaste, recuperás tus reservas.</p>
      <form onSubmit={enviar}>
        <input
          autoFocus
          value={nombre}
          onChange={(e) => setNombre(e.target.value)}
          placeholder="Tu nombre"
        />
        <button disabled={enviando || !nombre.trim()}>
          {enviando ? 'Registrando…' : 'Entrar'}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
    </div>
  )
}

function App() {
  const ruta = useRuta()
  const [usuario, setUsuario] = useState(usuarioGuardado)
  const [conectado, setConectado] = useState(true)

  // Estado de la conexión WebSocket, para avisar si se corta.
  useEffect(() => {
    return suscribir((mensaje) => {
      if (mensaje.type === 'conexion') {
        setConectado(mensaje.payload.conectado)
      }
    })
  }, [])

  // Si el backend se reseteó, el usuario guardado puede no existir más.
  useEffect(() => {
    if (usuario) {
      validar(usuario).then((existe) => {
        if (!existe) setUsuario(null)
      })
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  if (!usuario) {
    return <FormularioRegistro alRegistrar={setUsuario} />
  }

  return (
    <div className="app">
      <header>
        <a href="#/" className="marca">
          <Logo />
          Nomad<strong>Air</strong>
        </a>
        <nav>
          <a href="#/" className={ruta.pagina === 'vuelos' ? 'activo' : ''}>
            Vuelos
          </a>
          <a
            href="#/reservas"
            className={ruta.pagina === 'reservas' ? 'activo' : ''}
          >
            Mis reservas
          </a>
        </nav>
        <div className="usuario-box">
          <span className="quien">{usuario.nombre}</span>
          <button
            className="salir"
            title="Cerrar sesión"
            onClick={() => {
              cerrarSesion()
              setUsuario(null)
              window.location.hash = '#/'
            }}
          >
            Salir
          </button>
        </div>
      </header>

      {!conectado && (
        <div className="desconectado">
          Sin conexión con el servidor, reintentando…
        </div>
      )}

      <main>
        {ruta.pagina === 'vuelos' && <ListaVuelos />}
        {ruta.pagina === 'vuelo' && (
          <DetalleVuelo vueloId={ruta.vueloId} usuario={usuario} />
        )}
        {ruta.pagina === 'reservas' && <MisReservas usuario={usuario} />}
      </main>
    </div>
  )
}

export default App
