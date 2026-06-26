# TAL-29/25 - Investigación: Comunicación React ↔ Elixir mediante WebSockets

## Objetivo

Investigar cómo implementar la comunicación en tiempo real entre el frontend desarrollado en React y el backend desarrollado en Elixir utilizando WebSockets.

Los WebSockets permiten mantener una conexión persistente entre cliente y servidor, evitando realizar múltiples peticiones HTTP y posibilitando que el servidor envíe información en cualquier momento.

---

# 1. Apertura de una conexión WebSocket desde React

La API WebSocket está incorporada en todos los navegadores modernos.

Para abrir una conexión se crea una instancia indicando la dirección del servidor.

```javascript
const socket = new WebSocket("ws://localhost:4000/ws");
```

Cuando la conexión se establece correctamente se dispara el evento `onopen`.

```javascript
socket.onopen = () => {
    console.log("Conectado al servidor");
};
```

Si ocurre un error se dispara `onerror`.

```javascript
socket.onerror = (error) => {
    console.error(error);
};
```

Cuando la conexión se cierra se ejecuta `onclose`.

```javascript
socket.onclose = () => {
    console.log("Conexión cerrada");
};
```

En React normalmente la conexión se crea dentro de un `useEffect` para que se abra una única vez al montar el componente y se cierre al desmontarlo.

Ejemplo:

```javascript
useEffect(() => {

    const socket = new WebSocket("ws://localhost:4000/ws");

    return () => socket.close();

}, []);
```

---

# 2. Escuchar mensajes del servidor

Los mensajes enviados por el servidor llegan mediante el evento `onmessage`.

```javascript
socket.onmessage = (event) => {

    const mensaje = JSON.parse(event.data);

    console.log(mensaje);

};
```

El backend enviará mensajes en formato JSON.

Cada mensaje indicará mediante el campo `type` qué tipo de evento representa.

Ejemplo:

```json
{
    "type":"asiento_actualizado",
    "payload":{
        "vuelo_id":12,
        "asiento":"4A",
        "estado":"reservado"
    }
}
```

---

# 3. Actualizar el estado de React

Cuando llega un mensaje se actualiza el state utilizando `useState`.

Ejemplo:

```javascript
const [asientos, setAsientos] = useState([]);

socket.onmessage = (event) => {

    const mensaje = JSON.parse(event.data);

    if (mensaje.type === "asiento_actualizado") {

        setAsientos((anteriores) =>
            anteriores.map((a) =>
                a.numero === mensaje.payload.asiento
                    ? { ...a, estado: mensaje.payload.estado }
                    : a
            )
        );
    }
};
```

React vuelve a renderizar automáticamente el componente sin necesidad de recargar la página.

---

# 4. Enviar mensajes al servidor

Para enviar información se utiliza el método `send()`.

Como el protocolo del proyecto utiliza JSON, primero se serializa el objeto.

```javascript
socket.send(
    JSON.stringify({
        type: "reservar_asiento",
        request_id: "15",
        payload: {
            vuelo_id: 12,
            asiento: "4A",
            usuario_id: 8
        }
    })
);
```

El servidor recibirá este mensaje y responderá mediante otro mensaje JSON.

---

# 5. Actualización en tiempo real

La principal ventaja de WebSocket es que el servidor puede enviar información sin que el cliente la solicite.

Cuando un usuario reserva un asiento, el backend puede enviar inmediatamente un mensaje a todos los clientes conectados que estén observando ese vuelo.

Por ejemplo:

```json
{
    "type":"asiento_actualizado",
    "payload":{
        "vuelo_id":12,
        "asiento":"4A",
        "estado":"reservado"
    }
}
```

Cada cliente actualizará automáticamente su interfaz.

No es necesario recargar la página ni consultar periódicamente al servidor.

Esto resulta fundamental para evitar que dos usuarios visualicen información desactualizada.

---

# 6. Manejo de reconexión

Una conexión WebSocket puede cerrarse por distintos motivos:

- pérdida de Internet;
- reinicio del servidor;
- cierre del navegador;
- timeout de red.

Cuando ocurre esto se ejecuta el evento `onclose`.

Una estrategia simple consiste en intentar reconectarse automáticamente luego de algunos segundos.

Ejemplo:

```javascript
socket.onclose = () => {

    console.log("Intentando reconectar...");

    setTimeout(() => {

        conectarSocket();

    }, 3000);

};
```

La función `conectarSocket()` vuelve a crear un nuevo objeto WebSocket.

Es recomendable limitar la cantidad de reintentos o aumentar progresivamente el tiempo entre intentos (Backoff Exponencial) para evitar sobrecargar el servidor.

---

# 7. Aplicación al Trabajo Práctico

En este proyecto React enviará mensajes como:

- buscar_vuelos
- detalle_vuelo
- reservar_asiento
- confirmar_pago
- cancelar_reserva
- mis_reservas

El backend responderá con:

- *_ok
- error

Además enviará eventos push cuando cambie el estado del sistema:

- asiento_actualizado
- reserva_actualizada

Estos eventos permitirán que todos los usuarios conectados observen el mismo estado del vuelo en tiempo real.

---

# Conclusiones

El uso de WebSockets permite mantener una comunicación bidireccional permanente entre React y Elixir.

Esta tecnología resulta adecuada para aplicaciones donde múltiples usuarios interactúan simultáneamente sobre un mismo recurso, como ocurre en un sistema de reserva de asientos.

Combinado con OTP, GenServer y Registry, el backend podrá notificar inmediatamente los cambios de estado a todos los clientes conectados, garantizando una interfaz sincronizada y consistente.

Gráfico explicativo:

                React
                 │
         WebSocket (JSON)
                 │
      ┌─────────────────────┐
      │ Backend Elixir      │
      │                     │
      │ WebSocket Server    │
      │        │            │
      │     Registry        │
      │        │            │
      │   GenServer Vuelo   │
      │        │            │
      │ Persistencia        │
      └─────────────────────┘
                 │
      Eventos push a todos
      los clientes conectados