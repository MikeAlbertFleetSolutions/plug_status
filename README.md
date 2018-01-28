# PlugStatus

A plug for responding to status requests.

## Installation and docs

Add a dependency to your application's `mix.exs` file:

```elixir
defp deps do
  [{:plug_status, "MikeAlbertFleetSolutions/plug_status"}]
end
```

then run `mix deps.get`.

## Usage

```elixir
defmodule MyServer do
  use Plug.Builder
  plug PlugStatus

  # ... rest of the pipeline
end
```

Using a custom path is easy:

```elixir
defmodule MyServer do
  use Plug.Builder
  plug PlugStatus, path: "/status"

  # ... rest of the pipeline
end
```

## Build

#### To create docker image:

```bash
docker build --pull --tag plug_status -f Dockerfile .
```

## Testing

#### To create docker container from image during development:

```bash
docker run -it --rm -v ${WORKSPACE}/plug_status:/app -w /app plug_status
```

### To run the unit tests:

```bash
mix deps.get
mix test
```
