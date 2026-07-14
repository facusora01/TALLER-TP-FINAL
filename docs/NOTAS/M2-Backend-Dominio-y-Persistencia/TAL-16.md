# Tests de recuperación

Estos tests verifican que el estado del sistema se mantiene correctamente luego de reiniciar procesos.

## Decisión del sistema

Las reservas pendientes sobreviven al reinicio y continúan pendientes.

Se valida que:
- Los usuarios registrados siguen disponibles.
- Los vuelos mantienen su información.
- Las reservas confirmadas conservan el estado `:confirmada`.
- Las reservas pendientes conservan el estado `:pendiente`.
- Los asientos reservados mantienen el estado `:reservado`.