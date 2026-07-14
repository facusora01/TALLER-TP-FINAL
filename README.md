# NomadAir — Sistema de reserva de asientos en vuelos

Trabajo Práctico Final — Taller de Programación I.

Plataforma cliente-servidor para buscar vuelos de distintas aerolíneas, ver la
disponibilidad de asientos y reservarlos **en tiempo real**, resolviendo la
concurrencia entre múltiples usuarios (dos personas no pueden quedarse con el
mismo asiento, las reservas se confirman/cancelan/expiran de forma consistente y
todos los clientes que miran un vuelo ven los cambios al instante).

- **Backend:** Elixir + OTP (GenServer, Supervisores, Registry) con WebSockets
  sobre Cowboy. Estado persistido en DETS (sobrevive reinicios).
- **Frontend:** React + Vite, comunicándose con el backend por WebSocket.

---

## Requisitos

Para levantar con Docker (recomendado):

- Docker Desktop

Para levantar manualmente:

- Elixir `~> 1.17` con Erlang/OTP 27+
- Node.js 20+ y npm

---

## Cómo levantar el sistema

### Opción A — Docker (todo junto)

Desde la raíz del proyecto:

```bash
docker compose up --build
```

En Windows también podés hacer doble clic en **`start.bat`** (verifica que Docker
esté corriendo y levanta ambos servicios).

Esto deja disponible:

- **Frontend:** http://localhost:5173
- **Backend (WebSocket):** ws://localhost:4000/ws

Para frenarlo: `Ctrl+C` y `docker compose down`.

### Opción B — Manual (dos terminales)

Primero instalá **todas** las dependencias (backend + frontend) de una vez con:

```bash
setup.bat
```

O manualmente, cada una por su lado según los pasos de abajo.

**Backend:**

```bash
cd backend
mix deps.get             # (ya lo hace setup.bat)
mix run --no-halt        # o: iex -S mix
```

> En Windows PowerShell, `iex` es un alias del sistema; usá `iex.bat -S mix`.

El backend queda escuchando en `ws://localhost:4000/ws`.

**Frontend:**

```bash
cd frontend
npm install              # (ya lo hace setup.bat)
npm run dev
```

Abrí http://localhost:5173. El frontend se conecta por defecto a
`ws://<host>:4000/ws`; se puede sobreescribir con la variable `VITE_WS_URL`.

---

## Cómo probarlo

Tests del backend (dominio, protocolo, persistencia, recuperación, broadcast):

```bash
cd backend
mix test
```

---

## Arquitectura cliente-servidor

```
┌────────────┐   WebSocket (JSON)   ┌─────────────────────────────────────────┐
│  React     │ ───── mensajes ────► │  Cowboy  ·  /ws                          │
│  (Vite)    │                      │    │                                     │
│            │ ◄──── eventos ────── │    ▼                                     │
│  - Listado │      push en vivo    │  ConexionWS (1 proceso por cliente)      │
│  - Detalle │                      │    │  delega en                          │
│  - Reservas│                      │    ▼                                     │
└────────────┘                      │  Protocolo  ──►  GestorVuelos / Usuarios │
                                    │                      │                   │
                                    │                      ▼                   │
                                    │              ServidorVuelo (GenServer,   │
                                    │              uno por vuelo, único punto  │
                                    │              de escritura del estado)    │
                                    │                      │                   │
                                    │            persiste  ▼   notifica        │
                                    │                    DETS   Broadcast ─────┼──► push a
                                    │                                          │    suscriptores
                                    └─────────────────────────────────────────┘
```

- Cada **conexión WebSocket** es un proceso propio.
- Cada **vuelo** es un `GenServer` (`ServidorVuelo`) que serializa todas las
  operaciones sobre sus asientos → es imposible que dos usuarios se queden con
  el mismo asiento (no hay race conditions).
- Al cambiar un asiento, el `ServidorVuelo` **persiste** en DETS y **notifica**
  vía `Broadcast` a todos los clientes suscriptos a ese vuelo.

## Árbol de supervisión

```
Vuelos.Supervisor  (strategy: rest_for_one)
├── Vuelos.Persistencia            (GenServer · tablas DETS)
├── Registry  Vuelos.Registro      (:unique · lookup de ServidorVuelo por id)
├── Registry  Vuelos.Suscriptores  (:duplicate)
├── Vuelos.SupervisorDominio       (Supervisor · one_for_one)
│   ├── Vuelos.Usuarios            (GenServer · registro/login)
│   ├── Registry Vuelos.BroadcastRegistry  (:duplicate · suscriptores por vuelo)
│   └── Vuelos.SupervisorVuelos    (DynamicSupervisor · un ServidorVuelo por vuelo, on-demand)
├── Vuelos.SupervisorConexiones    (DynamicSupervisor · procesos de conexión)
├── Vuelos.SupervisorTareas        (Task.Supervisor · tareas auxiliares, ej. pago)
└── Vuelos.ServidorWeb             (Cowboy · HTTP/WS en :4000)
```

Separación de responsabilidades: **conexión** (ConexionWS), **dominio**
(ServidorVuelo, Usuarios) y **tareas auxiliares** (Task.Supervisor) están en
ramas distintas del árbol.

---

## Protocolo de mensajes (WebSocket)

Todos los mensajes son JSON con la forma:

```json
{ "type": "nombre", "request_id": "1", "payload": { } }
```

El servidor responde con `<type>_ok` reusando el `request_id`, o con un mensaje
`type: "error"` (`payload.codigo`, `payload.mensaje`). Además emite eventos
**push** sin `request_id` cuando cambia un vuelo suscripto.

| Cliente → Servidor | Descripción |
|---|---|
| `iniciar_sesion` | Login por nombre (crea o recupera el usuario) |
| `listar_vuelos` / `listar_aerolineas` | Listado y catálogo de aerolíneas |
| `buscar_vuelo` | Detalle de un vuelo |
| `obtener_asientos` | Estado de los asientos de un vuelo |
| `suscribir_vuelo` | Suscribe la conexión a los cambios de ese vuelo |
| `reservar_asiento` | Inicia una reserva (asiento → reservado) |
| `confirmar_reserva` | Confirma (asiento → confirmado) |
| `cancelar_reserva` | Cancela una reserva pendiente (libera el asiento) |
| `mis_reservas` | Reservas del usuario con su estado |

| Servidor → Cliente (push) | Descripción |
|---|---|
| `vuelo_actualizado` | Estado nuevo de los asientos de un vuelo (a todos los suscriptos) |

Estados de un **asiento**: `libre` · `reservado` · `confirmado`.
Estados de una **reserva**: `pendiente` · `confirmada` · `cancelada` · `expirada`.

---

## Persistencia y reinicio

El estado (usuarios, vuelos, asientos y reservas) se guarda en DETS bajo
`backend/data/`. Se puede **apagar y volver a levantar** el backend sin perder
información: los usuarios registrados, los vuelos, las reservas y el estado de
los asientos se restauran tal como estaban.

> Los datos iniciales (5 aerolíneas y 50 vuelos) se cargan una sola vez, cuando
> la tabla de vuelos está vacía. Para regenerarlos, borrá `backend/data/vuelos.dets`
> y reiniciá el backend.

---

## Demo básica paso a paso

1. Abrí http://localhost:5173 e ingresá con un nombre.
2. En el listado, filtrá por fecha/destino y **ordená por precio**.
3. Entrá a un vuelo → se ve el **mapa de asientos** (disponible / reservado / confirmado).
4. Clic en un asiento libre → se crea la **reserva (pendiente)**.
5. Andá a **Mis reservas** → **Confirmar** (asiento → confirmado) o **Cancelar**.
6. **Tiempo real:** abrí una segunda pestaña en el mismo vuelo; al reservar en
   una, la otra se actualiza sola.
7. **Persistencia:** frená el backend y volvé a levantarlo → tus reservas y el
   estado de los asientos siguen ahí.

---

## Estructura del repositorio

```
├── backend/          Aplicación Elixir + OTP (mix)
│   ├── lib/vuelos/    Dominio, protocolo, WebSocket, persistencia, supervisión
│   ├── test/          Tests (ExUnit)
│   └── data/          Tablas DETS (generadas en runtime)
├── frontend/          Aplicación React + Vite
│   └── src/           App, páginas y cliente WebSocket
├── docs/              Enunciado y notas de diseño
├── docker-compose.yml
├── setup.bat          Instala las dependencias de backend y frontend de una vez
└── start.bat          Atajo para levantar todo con Docker en Windows
```
