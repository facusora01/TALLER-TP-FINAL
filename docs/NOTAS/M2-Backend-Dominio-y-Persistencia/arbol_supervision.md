# Árbol de Supervisión OTP

## Diagrama

```
Vuelos.Aplicacion (Application)
└── Vuelos.Supervisor (raíz, strategy: :rest_for_one)
      ├── Vuelos.Persistencia
      ├── Registry (Vuelos.Registro, keys: :unique)
      ├── Registry (Vuelos.Suscriptores, keys: :duplicate)
      ├── Vuelos.SupervisorDominio (strategy: :one_for_one)
      │     ├── Vuelos.Usuarios
      │     ├── Registry (Vuelos.BroadcastRegistry, keys: :duplicate)
      │     └── Vuelos.SupervisorVuelos (DynamicSupervisor)
      │           ├── ServidorVuelo "ARC-001"
      │           ├── ServidorVuelo "FLS-003"
      │           └── ... (creados bajo demanda)
      ├── Vuelos.SupervisorConexiones (DynamicSupervisor)
      │     ├── ConexionWS cliente 1
      │     ├── ConexionWS cliente 2
      │     └── ...
      ├── Vuelos.SupervisorTareas (Task.Supervisor)
      │     ├── Tarea: pago simulado reserva X
      │     └── ...
      └── Vuelos.ServidorWeb
```

---

## Descripción de cada parte

### Vuelos.Aplicacion
Punto de entrada de la aplicación. Elixir lo llama automáticamente al arrancar con `mix run`. Arranca el árbol de supervisión y carga los datos iniciales via `Vuelos.Seeds`.

### Vuelos.Supervisor (raíz)
Supervisor principal del sistema. Usa estrategia `:rest_for_one`: si un hijo muere, reinicia ese hijo y todos los que le siguen en la lista. Esto es necesario porque los hijos tienen dependencias en orden — si muere `Persistencia`, `SupervisorDominio` también tiene que reiniciarse porque depende de DETS.

### Vuelos.Persistencia
Abre y mantiene las tablas DETS al arrancar. Es el primero en levantarse porque todos los demás dependen de él para leer y escribir datos persistidos. Las tablas que maneja son: `:usuarios`, `:vuelos`, `:asientos`, `:reservas`.

### Registry (Vuelos.Registro, keys: :unique)
Directorio de procesos del sistema. Permite encontrar cualquier proceso por nombre en vez de por PID. Se usa para encontrar el `ServidorVuelo` de un vuelo específico por su id. Al ser `:unique`, no puede haber dos procesos registrados bajo la misma clave.

### Registry (Vuelos.Suscriptores, keys: :duplicate)
Registry con `keys: :duplicate` disponible en el supervisor raíz. Al ser duplicado, permite que múltiples procesos se registren bajo la misma clave, igual que `Vuelos.BroadcastRegistry`.

### Vuelos.SupervisorDominio
Subárbol especializado que agrupa la lógica de negocio. Separa el dominio de la infraestructura (`Persistencia`, `Registry`) y de la red (`SupervisorConexiones`, `ServidorWeb`). Usa `:one_for_one`: si un hijo muere, solo se reinicia ese hijo.

### Vuelos.Usuarios
GenServer que maneja todos los usuarios registrados. Al arrancar, carga los usuarios persistidos en DETS a memoria (`hidratar`). En ejecución, responde consultas desde memoria y guarda cambios en DETS.

### Registry (Vuelos.BroadcastRegistry, keys: :duplicate)
Registry interno del dominio usado por `Vuelos.Broadcast`. Cuando un cliente se suscribe a un vuelo, su proceso `ConexionWS` se registra acá bajo el id del vuelo. Cuando cambia el estado de un vuelo, `Broadcast.notificar` usa este registry para encontrar a todos los suscriptores y mandarles la actualización.

### Vuelos.SupervisorVuelos (DynamicSupervisor)
Supervisor dinámico que aloja los procesos `ServidorVuelo`. Cada `ServidorVuelo` se arranca la primera vez que alguien consulta o opera sobre ese vuelo — no al arrancar el sistema. Si el proceso ya existe, se reutiliza. Si no existe o murió, `GestorVuelos` lo arranca automáticamente bajo este supervisor.

### ServidorVuelo (uno por vuelo)
GenServer que maneja el estado de un vuelo específico: sus asientos y sus reservas. Es el único punto de escritura para ese vuelo, lo que garantiza consistencia ante accesos concurrentes. Maneja el ciclo de vida completo de las reservas: pendiente → confirmada / cancelada / expirada. Después de cada cambio llama a `Vuelos.Broadcast.notificar` para avisar a los clientes conectados.

### Vuelos.SupervisorConexiones (DynamicSupervisor)
Supervisor dinámico que arranca un proceso por cada usuario conectado via WebSocket. Es dinámico porque las conexiones ocurren en tiempo de ejecución. Cuando el usuario se desconecta, el proceso asociado termina y el supervisor lo elimina.

### Vuelos.SupervisorTareas (Task.Supervisor)
Supervisor para tareas cortas y auxiliares que nacen, hacen algo, y mueren. Actualmente se usa para el pago simulado: lanza una tarea que espera entre 1 y 5 segundos e intenta confirmar la reserva.

### Vuelos.ServidorWeb
Levanta el listener HTTP de Cowboy y expone el WebSocket en `/ws`. Es el punto de entrada de las conexiones desde el frontend. Cuando llega una conexión WebSocket, Cowboy crea un proceso `Vuelos.ConexionWS` bajo `SupervisorConexiones`. Va al final de la lista para asegurarse de que todo el dominio esté listo antes de aceptar conexiones.

---

## Decisiones de diseño

**¿Por qué `:rest_for_one` en el supervisor raíz?**
Porque los hijos tienen dependencias en orden. `Persistencia` tiene que estar activo para que `SupervisorDominio` pueda leer de DETS. Si se usara `:one_for_one` y `Persistencia` muriera, `Usuarios` seguiría corriendo con DETS cerrado, lo que causaría errores.

**¿Por qué `DynamicSupervisor` para vuelos y conexiones?**
Porque la cantidad de vuelos activos y conexiones no se conoce al arrancar. Los `ServidorVuelo` se arrancan bajo demanda, las conexiones llegan en tiempo de ejecución. Un supervisor normal requiere definir los hijos de antemano.

**¿Por qué un `SupervisorDominio` separado?**
Para separar responsabilidades: la infraestructura (`Persistencia`, `Registry`) del dominio (`Usuarios`, vuelos) y de la red (`SupervisorConexiones`, `ServidorWeb`). Hace el árbol más claro y más fácil de mantener.

**¿Por qué un proceso por vuelo y no uno para todos?**
Para evitar cuellos de botella. Si un solo proceso manejara todos los vuelos, las operaciones sobre distintos vuelos se serializarían innecesariamente. Con un proceso por vuelo, los vuelos operan en paralelo sin interferirse.

**¿Por qué dos Registries para broadcast (`Vuelos.Suscriptores` y `Vuelos.BroadcastRegistry`)?**
`BroadcastRegistry` es el que usa `Vuelos.Broadcast` internamente para despachar notificaciones. `Vuelos.Suscriptores` es un Registry duplicado disponible en el supervisor raíz para uso general.

**¿Por qué `ServidorWeb` va al final de la lista?**
Porque tiene que arrancar después de que todo el dominio esté listo. Si `ServidorWeb` arrancara primero y llegara una conexión antes de que `Persistencia` o `Usuarios` estuvieran listos, el sistema fallaría.
