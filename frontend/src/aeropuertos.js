// Aeropuertos nacionales usados en los seeds, con su ciudad.

export const AEROPUERTOS = {
  EZE: 'Buenos Aires — Ezeiza',
  AEP: 'Buenos Aires — Aeroparque',
  COR: 'Córdoba',
  MDZ: 'Mendoza',
  BRC: 'Bariloche',
  IGR: 'Puerto Iguazú',
  USH: 'Ushuaia',
  NQN: 'Neuquén',
  SLA: 'Salta',
  TUC: 'Tucumán',
}

export function ciudad(codigo) {
  return AEROPUERTOS[codigo] || codigo
}

// Normaliza para comparar lo tipeado: minúsculas y sin acentos.
export function normalizar(texto) {
  return texto
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
}

/** true si lo tipeado coincide con el código o la ciudad del aeropuerto. */
export function coincideDestino(codigo, tipeado) {
  const buscado = normalizar(tipeado.trim())
  if (!buscado) return true
  return (
    normalizar(codigo).includes(buscado) ||
    normalizar(ciudad(codigo)).includes(buscado)
  )
}
