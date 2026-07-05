import Config

config :vuelos,
  puerto_web: 4000,
  demora_pago_ms: {1_000, 5_000}

import_config "#{config_env()}.exs"
