defmodule PlugStatus do
  @default_path "/__status"

  @moduledoc """
  A plug for responding to status requests, returns performance metrics.

  This plug responds with a successful status to `GET` requests at a
  specific path so that clients can get status information.

  The response that this plug sends is a *200* response with a json body containing
  status information, the path that responds to this request is `#{@default_path}`,
  but it can be configured.

  Note that this plug **halts the connection**. This is done so that it can be
  plugged near the top of a plug pipeline and catch requests early so that
  subsequent plugs don't have the chance to tamper with the connection.
  Read more about halting connections in the docs for [`Plug.Builder`](http://hexdocs.pm/plug/Plug.Builder.html).

  ## Information returned

  The following information below is returned.

    * `memory` - all information from Erlang VM call [`memory/0`](http://erlang.org/doc/man/erlang.html#memory-0)
    * `statistics` - These items from Erlang VM call [`statistics/1`](http://erlang.org/doc/man/erlang.html#statistics-1):
                      :active_tasks,
                      :context_switches,
                      :garbage_collection,
                      :io,
                      :run_queue,
                      :run_queue_lengths,
                      :scheduler_wall_time,
                      :total_active_tasks,
                      :total_run_queue_lengths
    * `system_info` - These items from Erlang VM call [`system_info/1`](http://erlang.org/doc/man/erlang.html#system_info-1):
                      :atom_count,
                      :atom_limit,
                      :otp_release,
                      :port_count,
                      :port_limit,
                      :process_count,
                      :process_limit,
                      :schedulers,
                      :schedulers_online,
                      :thread_pool_size,
                      :version

  ## Options

  The following options can be used when calling `plug PlugStatus`.

    * `:path` - a string specifying the path on which `PlugStatus` will respond
      to status requests

  ## Examples

      defmodule MyServer do
        use Plug.Builder
        plug PlugStatus

        # ... rest of the pipeline
      end

  Using a custom path:

      defmodule MyServer do
        use Plug.Builder
        plug PlugStatus, path: "/status"

        # ... rest of the pipeline
      end

  """

  @behaviour Plug
  import Plug.Conn

  def init(opts), do: Keyword.merge([path: @default_path], opts)

  def call(%Plug.Conn{} = conn, opts) do
    if conn.request_path == opts[:path] and conn.method == "GET" do
      conn
      |> halt
      |> send_status()
    else
      conn
    end
  end

  defp send_status(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      Poison.encode!(%{
        "erlangvm" => %{
          "memory" => memory(),
          "statistics" => statistics(),
          "system_info" => system_info()
        }
      })
    )
  end

  defp memory do
    :erlang.memory()
    |> Enum.into(%{})
  end

  defp statistics do
    [
      :active_tasks,
      :context_switches,
      :garbage_collection,
      :io,
      :run_queue,
      :run_queue_lengths,
      :scheduler_wall_time,
      :total_active_tasks,
      :total_run_queue_lengths
    ]
    |> Stream.map(fn x ->
      stat({x, :erlang.statistics(x)})
    end)
    |> Enum.into(%{})
  end

  defp system_info do
    [
      :atom_count,
      :atom_limit,
      :otp_release,
      :port_count,
      :port_limit,
      :process_count,
      :process_limit,
      :schedulers,
      :schedulers_online,
      :thread_pool_size,
      :version
    ]
    |> Stream.map(fn x ->
      sysinfo({x, :erlang.system_info(x)})
    end)
    |> Enum.into(%{})
  end

  # statistics formatting helpers
  defp stat({k, v}) when k == :context_switches do
    # {context_switches, {ContextSwitches, 0}}
    {k, {contextswitches, 0}} = {k, v}
    {k, contextswitches}
  end

  defp stat({k, v}) when k == :garbage_collection do
    # {garbage_collection, {Number_of_GCs, Words_Reclaimed, 0}}
    {k, {number_of_gcs, words_reclaimed, 0}} = {k, v}
    {k, %{:number_of_gcs => number_of_gcs, :words_reclaimed => words_reclaimed}}
  end

  defp stat({k, v}) when k == :io do
    # {io: {{input, Input}, {output, Output}}}
    {k, {{_input, input}, {_output, output}}} = {k, v}
    {k, %{:input => input, :output => output}}
  end

  defp stat({k, v}), do: {k, v}

  # system_info formatting helpers
  defp sysinfo({k, v}) when k in [:otp_release, :version], do: {k, String.Chars.to_string(v)}
  defp sysinfo({k, v}), do: {k, v}
end
