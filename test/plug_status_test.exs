defmodule PlugStatusTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @default_path "/__status"
  @custom_path "/custom"

  defmodule DefaultPath do
    use Plug.Router
    plug(PlugStatus)
    plug(:match)
    plug(:dispatch)
    match(_, do: send_resp(conn, 200, "match"))
  end

  defmodule CustomPath do
    @custom_path "/custom"

    use Plug.Router
    plug(PlugStatus, path: @custom_path)
    plug(:match)
    plug(:dispatch)
    match(_, do: send_resp(conn, 200, "match"))
  end

  defmodule Halted do
    use Plug.Router
    plug(PlugStatus)
    plug(:match)
    plug(:dispatch)
    plug(:body_after)

    defp body_after(conn, _opts), do: %{conn | resp_body: "after"}

    match(_, do: send_resp(conn, 200, "match"))
  end

  test "default path" do
    conn = conn(:get, @default_path) |> DefaultPath.call([])
    assert conn.status == 200
    assert conn |> get_resp_header("content-type") |> hd =~ "application/json"
    refute conn.resp_body == "after"
  end

  test "the connection is halted after the status (by default)" do
    conn = conn(:get, @default_path) |> Halted.call([])
    assert conn.status == 200
    assert conn |> get_resp_header("content-type") |> hd =~ "application/json"
  end

  test "custom path" do
    conn = conn(:get, @custom_path) |> CustomPath.call([])
    assert conn.status == 200
    assert conn |> get_resp_header("content-type") |> hd =~ "application/json"
  end

  test "only GET requests work" do
    Enum.each([:post, :put, :delete, :options, :foo], fn method ->
      conn = conn(method, @default_path) |> DefaultPath.call([])
      assert conn.resp_body == "match"
    end)

    # HEAD is a special case, Plug.Adapters.Test.Conn returns empty body
    conn = conn(:head, @default_path) |> DefaultPath.call([])
    assert conn.resp_body == ""
  end

  test "only matching requests are halted" do
    conn = conn(:get, "/passthrough") |> DefaultPath.call([])
    assert conn.status == 200
    assert conn.resp_body == "match"

    conn = conn(:get, "/passthrough") |> CustomPath.call([])
    assert conn.status == 200
    assert conn.resp_body == "match"
  end
end
