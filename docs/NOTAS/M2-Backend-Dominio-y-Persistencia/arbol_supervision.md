# Árbol de Supervisión OTP

## Diagrama

```
Vuelos.Aplicacion (Application)
└── Vuelos.Supervisor (raíz, strategy: :rest_for_one)
      ├── Vuelos.Persistencia
      ├── Registry (Vuelos.Registro)
      ├── Vuelos.SupervisorDominio (strategy: :one_for_one)
      │     ├── Vuelos.Usuarios
      │     └── Vuelos.SupervisorVuelos (DynamicSupervisor)
      ├── Vuelos.SupervisorConexiones (DynamicSupervisor)
      ├── Vuelos.SupervisorTareas (Task.Supervisor)
      └── Vuelos.ServidorWeb
```

---

## Descripción de cada parte

### Vuelos.Aplicacion
Punto de entrada de la aplicación. Elixir lo llama automáticamente al arrancar con `mix run`. Su único trabajo es arrancar el árbol de supervisión y cargar los datos iniciales via `Vuelos.Seeds`.

### Vuelos.Supervisor (raíz)
Supervisor principal del sistema. Usa estrategia `:rest_for_one`: si un hijo muere, reinicia ese hijo y todos los que le siguen en la lista. Esto es importante porque los hijos tienen dependencias en orden — si muere `Persistencia`, `Usuarios` también tiene que reiniciarse porque depende de DETS.

### Vuelos.Persistencia
Abre y mantiene las tablas DETS al arrancar. Es el primero en levantarse porque todos los demás dependen de él para leer y escribir datos persistidos. Las tablas que maneja son: `:usuarios`, `:vuelos`, `:asientos`, `:reservas`.

### Registry (Vuelos.Registro)
Directorio de procesos del sistema. Permite encontrar cualquier proceso por nombre en vez de por PID. Se usa para:
- Encontrar el `ServidorVuelo` de un vuelo específico por su id
- Encontrar los procesos de conexión que están mirando un vuelo (para broadcast)

### Vuelos.SupervisorDominio
Subárbol especializado que agrupa la lógica de negocio. Separa el dominio de la infraestructura (`Persistencia`, `Registry`) y de las conexiones. Usa `:one_for_one`: si un hijo muere, solo se reinicia ese hijo.

### Vuelos.Usuarios
GenServer que maneja todos los usuarios registrados. Al arrancar, carga los usuarios persistidos en DETS a memoria (`hidratar`). En ejecución, responde consultas desde memoria y guarda cambios en DETS.

### Vuelos.SupervisorVuelos (DynamicSupervisor)
Supervisor dinámico que arranca un `ServidorVuelo` por cada vuelo cargado en el sistema. Es dinámico porque la cantidad de vuelos no se conoce de antemano — se lee de DETS al arrancar.

### ServidorVuelo (uno por vuelo)
GenServer que maneja el estado de un vuelo específico: sus asientos y sus reservas. Es el único punto de escritura para ese vuelo, lo que garantiza consistencia ante accesos concurrentes. Maneja el ciclo de vida completo de las reservas: pendiente → confirmada / cancelada / expirada.

### Vuelos.SupervisorConexiones (DynamicSupervisor)
Supervisor dinámico que arranca un proceso por cada usuario conectado via WebSocket. Es dinámico porque las conexiones ocurren en tiempo de ejecución. Cuando el usuario cierra el frontend, el proceso muere y el supervisor lo elimina.

### Vuelos.SupervisorTareas (Task.Supervisor)
Supervisor para tareas cortas y auxiliares que nacen, hacen algo, y mueren:
- **Pago simulado**: espera entre 1 y 5 segundos e intenta confirmar la reserva
- **Timer de expiración**: espera 1 minuto y expira la reserva si sigue pendiente

---

## Decisiones de diseño

**¿Por qué `:rest_for_one` en el supervisor raíz?**
Porque los hijos tienen dependencias en orden. `Persistencia` tiene que estar activo para que `Usuarios` pueda leer de DETS. Si se usara `:one_for_one` y `Persistencia` muriera, `Usuarios` seguiría corriendo con DETS cerrado, lo que causaría errores.

**¿Por qué `DynamicSupervisor` para vuelos y conexiones?**
Porque la cantidad de vuelos y conexiones no se conoce al arrancar. Los vuelos se leen de DETS, las conexiones llegan en tiempo de ejecución. Un supervisor normal requiere definir los hijos de antemano.

**¿Por qué un `SupervisorDominio` separado?**
Para separar responsabilidades: la infraestructura (`Persistencia`, `Registry`) del dominio (`Usuarios`, vuelos) y de la red (`SupervisorConexiones`). Hace el árbol más claro y más fácil de mantener.

**¿Por qué un proceso por vuelo y no uno para todos?**
Para evitar cuellos de botella. Si un solo proceso manejara todos los vuelos, las operaciones sobre distintos vuelos se serializarían innecesariamente. Con un proceso por vuelo, los vuelos operan en paralelo sin interferirse.
