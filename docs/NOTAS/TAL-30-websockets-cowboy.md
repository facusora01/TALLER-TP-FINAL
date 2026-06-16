# TAL-30 · WebSockets en Elixir con Cowboy

Investigacion inicial: como abrir una conexion WebSocket, recibir/enviar
mensajes y manejar la desconexion. El uso posta (broadcast, tiempo real) lo
vemos mas adelante.

## Por que Cowboy

Es el servidor HTTP de Erlang y ya trae WebSocket nativo (`:cowboy_websocket`).
Lo usamos en vez de Phoenix para laburar OTP y WebSockets "a mano": un proceso
por cada conexion.


## Como funciona

- Arrancas un listener de Cowboy con un router que apunta `/ws` al handler.
- Cuando un cliente se conecta, Cowboy **levanta un proceso dedicado** para esa
  conexion (queda aislada del resto).
- Los callbacks basicos del handler:
  - `init/2` => pide el upgrade a WebSocket (la conexion)
  - `websocket_handle/2` => mensaje que llega del cliente (parseas el JSON)
  - `terminate/3` => desconexion


# Entonces

Basicamente el WebSocket es un proceso que sirve para que el cliente y el servidor
se comuniquen en tiempo real. El cliente manda mensajes (ej: "quiero reservar")
y el servidor responde (ej: "reserva confirmada"). El proceso se encarga de
mantener esa conexion abierta y manejar los mensajes que llegan.
Ademas te ahorras lo de tener que ir apretando el F5 para ver los cambios, porque el WebSocket es dinamico y en tiempo real.

y el orden seria algo asi:

1. Arranco el listener de Cowboy en el `Application` (con el router).
2. Creo el handler con los callbacks basicos (init, handle, terminate).
3. Pruebo la conexion con un cliente WebSocket (ej: `wscat`).



## Referencia

https://ninenines.eu/docs/en/cowboy/2.12/guide/ws_handlers/
