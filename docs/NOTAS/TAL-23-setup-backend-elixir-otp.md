# TAL-23 · Setup proyecto Elixir/OTP

El back lo armamos con un solo comando:

```bash
mix new backend --app vuelos --module Vuelos --sup
```

- `backend` => carpeta donde se crea
- `--app vuelos` => nombre de la app OTP (`:vuelos`)
- `--module Vuelos` => modulo raiz
- `--sup` => ya te genera el `Application` + el supervisor raiz

Queda en `backend/` con la estructura tipica de mix (`lib/`, `test/`, `mix.exs`).
Las dependencias (Cowboy, Jason) y el arbol de supervision real los agregamos
mas adelante, en M2/M3.
