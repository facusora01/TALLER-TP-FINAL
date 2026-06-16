# TAL-27 · Arquitectura de procesos OTP

Esto es el diseño inicial del arbol de supervision, para tenerlo claro antes de
ponernos a codear. Los detalles mas finos (concurrencia, expiracion, etc.) los
dejamos para cuando implementemos.

## Tipos de proceso

Vamos a tener tres tipos:

1. **Conexion** => uno por cada cliente WebSocket (van y vienen, son dinamicos).
2. **Dominio** => los que guardan el estado (vuelos, reservas, usuarios).
3. **Auxiliares** => tareas con tiempo (expiracion, pago simulado).

La idea base: **el estado de cada vuelo vive en un solo proceso (GenServer)**,
asi las operaciones sobre ese vuelo quedan ordenadas.

## Arbol de supervision (borrador)

```
Vuelos.Application
└── Vuelos.Supervisor (raiz, :one_for_one)
    ├── Vuelos.Registry            lookup {:flight, id} / {:conn, id}
    ├── Vuelos.Users               GenServer de usuarios
    ├── Vuelos.Persistence         dueño de DETS
    ├── Vuelos.Flights.Supervisor  DynamicSupervisor => 1 GenServer por vuelo
    ├── Vuelos.ConnSupervisor      DynamicSupervisor => 1 proceso por conexion
    ├── Vuelos.Tasks.Supervisor    DynamicSupervisor => pago simulado
    └── :cowboy listener           servidor HTTP/WS
```

## Que decidimos

- **Registry**: si. Sirve para encontrar procesos por una clave (ej: el id del
  vuelo), porque el PID cambia si el proceso se reinicia.
- **DynamicSupervisor**: si, para todo lo que se crea en runtime y en cantidad
  variable (vuelos, conexiones, tareas auxiliares).
- **Supervisor normal**: para los procesos que ya estan al arrancar
  (Registry, Users, Persistence).
