FROM elixir:latest

WORKDIR /app

COPY mix.exs ./

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get

COPY . .

RUN mix compile

COPY aos /app/aos

CMD ["iex", "-S", "mix"]