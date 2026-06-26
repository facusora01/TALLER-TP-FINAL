# Diseño del protocolo de comunicación React ↔ Elixir

## Objetivo

Definir el protocolo de comunicación entre el frontend desarrollado en React y el backend desarrollado en Elixir mediante WebSockets.

El protocolo establece el formato de todos los mensajes intercambiados entre cliente y servidor, incluyendo solicitudes, respuestas, errores y eventos enviados en tiempo real.

---

# 1. Formato general de los mensajes

Todos los mensajes utilizarán JSON con la siguiente estructura:

```json
{
  "type": "nombre_del_mensaje",
  "request_id": "uuid-opcional",
  "payload": {}
}
```

## Campos

| Campo      | Descripción                                                         |
| ---------- | ------------------------------------------------------------------- |
| type       | Tipo de mensaje.                                                    |
| request_id | Identificador de la solicitud para relacionar respuesta y petición. |
| payload    | Datos específicos del mensaje.                                      |

---

# 2. Mensajes enviados por el cliente

## Buscar vuelos

```json
{
  "type": "buscar_vuelos",
  "request_id": "1",
  "payload": {
    "fecha": "2026-07-15",
    "destino": "Bariloche",
    "orden": "precio"
  }
}
```

---

## Obtener detalle de un vuelo

```json
{
  "type": "detalle_vuelo",
  "request_id": "2",
  "payload": {
    "vuelo_id": 15
  }
}
```

---

## Reservar un asiento

```json
{
  "type": "reservar_asiento",
  "request_id": "3",
  "payload": {
    "usuario_id": 8,
    "vuelo_id": 15,
    "asiento": "3C"
  }
}
```

---

## Confirmar una reserva

```json
{
  "type": "confirmar_pago",
  "request_id": "4",
  "payload": {
    "reserva_id": 99
  }
}
```

---

## Cancelar una reserva

```json
{
  "type": "cancelar_reserva",
  "request_id": "5",
  "payload": {
    "reserva_id": 99
  }
}
```

---

## Obtener reservas del usuario

```json
{
  "type": "mis_reservas",
  "request_id": "6",
  "payload": {
    "usuario_id": 8
  }
}
```

---

# 3. Respuestas del servidor

Cuando una operación finaliza correctamente el servidor responde utilizando el mismo `request_id`.

Ejemplo:

```json
{
  "type": "reservar_asiento_ok",
  "request_id": "3",
  "payload": {
    "reserva_id": 99,
    "estado": "pendiente",
    "vence_en": 60
  }
}
```

Otros mensajes exitosos:

* buscar_vuelos_ok
* detalle_vuelo_ok
* confirmar_pago_ok
* cancelar_reserva_ok
* mis_reservas_ok

---

# 4. Representación de errores

Todos los errores utilizan el mismo formato.

```json
{
  "type": "error",
  "request_id": "3",
  "payload": {
    "codigo": "ASIENTO_OCUPADO",
    "mensaje": "El asiento ya fue reservado."
  }
}
```

## Códigos de error

* VUELO_NO_EXISTE
* ASIENTO_NO_EXISTE
* ASIENTO_OCUPADO
* RESERVA_NO_EXISTE
* RESERVA_EXPIRADA
* RESERVA_CONFIRMADA
* RESERVA_CANCELADA
* USUARIO_NO_EXISTE
* ERROR_INTERNO

---

# 5. Eventos enviados por el servidor

El servidor puede enviar mensajes sin que el cliente los solicite.

Estos mensajes permiten mantener sincronizados todos los clientes conectados.

## Actualización de asiento

```json
{
  "type": "asiento_actualizado",
  "payload": {
    "vuelo_id": 15,
    "asiento": "3C",
    "estado": "reservado"
  }
}
```

---

## Actualización de reserva

```json
{
  "type": "reserva_actualizada",
  "payload": {
    "reserva_id": 99,
    "estado": "confirmada"
  }
}
```

Los estados posibles son:

* pendiente
* confirmada
* cancelada
* expirada

---

# 6. Estados del sistema

## Estados de un asiento

* libre
* reservado
* confirmado

## Estados de una reserva

* pendiente
* confirmada
* cancelada
* expirada

---

# 7. Flujo general de comunicación

```text
React
   │
buscar_vuelos
   │
   ▼
Backend Elixir

buscar_vuelos_ok
   ▲

──────────────

detalle_vuelo
   ▼

detalle_vuelo_ok
   ▲

──────────────

reservar_asiento
   ▼

reservar_asiento_ok
   ▲

(push)
asiento_actualizado
   ▲

──────────────

confirmar_pago
   ▼

confirmar_pago_ok
   ▲

(push)
reserva_actualizada
   ▲

(push)
asiento_actualizado
```

---

# Conclusiones

El protocolo define un formato único para toda la comunicación entre React y Elixir.

La utilización de mensajes JSON con un campo `type` simplifica el procesamiento tanto en el frontend como en el backend. Además, los eventos enviados por el servidor permiten mantener sincronizados todos los clientes conectados y resolver correctamente las situaciones concurrentes planteadas por el trabajo práctico.
