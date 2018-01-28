FROM elixir:latest

# app install
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app
CMD [ "bash" ]
