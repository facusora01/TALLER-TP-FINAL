// Manejo del usuario actual: se registra una vez y se recuerda en localStorage.

import { pedir } from './ws'

const CLAVE = 'vuelos.usuario'

export function usuarioGuardado() {
  try {
    return JSON.parse(localStorage.getItem(CLAVE))
  } catch {
    return null
  }
}

export function cerrarSesion() {
  localStorage.removeItem(CLAVE)
}

// Login sin contraseña: identifica por nombre. Si el nombre ya existe, el
// backend devuelve ese mismo usuario, así se recuperan las reservas al volver.
export async function iniciarSesion(nombre) {
  const payload = await pedir('iniciar_sesion', { nombre })
  const usuario = { id: payload.usuario_id, nombre: payload.nombre }
  localStorage.setItem(CLAVE, JSON.stringify(usuario))
  return usuario
}

/** Valida contra el backend que el usuario guardado siga existiendo. */
export async function validar(usuario) {
  try {
    await pedir('obtener_usuario', { usuario_id: usuario.id })
    return true
  } catch (error) {
    if (error.codigo === 'USUARIO_NO_EXISTE') {
      localStorage.removeItem(CLAVE)
      return false
    }
    return true // ante un timeout no descartamos al usuario
  }
}
