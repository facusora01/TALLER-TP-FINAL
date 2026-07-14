# Backend Elixir: servidor de vuelos con WebSocket en el puerto 4000.
FROM elixir:1.18-alpine

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config config
COPY lib lib

RUN mix compile

EXPOSE 4000

CMD ["mix", "run", "--no-halt"]
