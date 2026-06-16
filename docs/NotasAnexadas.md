# Notas Anexadas — TP Final

Para el TP final, estos son los temas que cada grupo ya debería empezar a investigar / resolver por su cuenta:

## 1. WebSockets en Elixir

- Cómo levantar una conexión
- Cómo recibir y enviar mensajes
- Cómo manejar conexión y desconexión
- Para esto pueden usar **Cowboy**

## 2. Protocolo de mensajes entre frontend y backend

- Qué mensajes envía el cliente
- Qué responde el servidor
- Cómo representar errores
- Cómo representar eventos / actualizaciones push

## 3. Manejo de clientes conectados

- Qué proceso representa una conexión
- Cómo saber qué vuelo está mirando cada cliente
- Qué clientes deben recibir actualizaciones
- Qué pasa cuando un cliente se desconecta

## 4. Broadcast y tiempo real

- Cómo propagar cambios del backend a múltiples clientes
- Cómo actualizar correctamente a todos los que están viendo el mismo vuelo

## 5. Arquitectura de procesos del sistema

- Procesos de conexión
- Procesos de dominio
- Procesos auxiliares
- Si conviene usar **Registry**
- Si conviene usar **DynamicSupervisor**

## 6. Persistencia obligatoria

- Persistir usuarios registrados
- Persistir vuelos
- Persistir estado de asientos
- Persistir reservas
- Apagar el servidor y volver a levantarlo conservando ese estado
- Para esto pueden usar **DETS** si lo desean

## 7. Integración frontend + WebSocket

- Abrir la conexión desde React
- Escuchar mensajes del servidor
- Actualizar el estado de la UI
- Reflejar cambios en tiempo real sin recargar

## 8. Expiración de reservas

- La reserva expira al 1 minuto si no se confirma el pago
- Cómo modelar timers, procesos auxiliares o mensajes diferidos

## 9. Pago simulado asincrónico

- Tarda entre 1 y 5 segundos
- Cómo modelar ese paso
- Cómo hacerlo convivir correctamente con la expiración

## 10. Casos concurrentes importantes

- Dos usuarios queriendo el mismo asiento
- Confirmación y expiración compitiendo
- Cancelación y confirmación compitiendo
- Clientes trabajando con información vieja
- Reinicio del servidor con estado persistido

---

**Lo que no deberían tener que inventar desde cero** es el modelo conceptual de procesos, GenServer, Supervisor, Application y concurrencia básica. Eso es parte de lo que estamos viendo en la materia.

**Lo que sí tienen que empezar a investigar ahora** es cómo llevar todo eso a una aplicación cliente-servidor real con WebSockets, frontend y persistencia.
