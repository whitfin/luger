defmodule Luger do
  @moduledoc """
  A plug for logging basic request information in the format:

      17:26:06.192 [info]  POST /path - 200 - 794µs - 127.0.0.1

  ## Options

    * `:include_ip` - Whether or not to include the remote_ip field in the log
      message. Default is `true`.
    * `:level` - The log level at which this plug should log its request info.
      Default is `:info`.

  """
  defstruct [:level, :include_ip]

  # inherit behaviour of Plug
  @behaviour Plug

  # add some typing
  @opaque t :: %__MODULE__{}

  # add a message alias
  alias __MODULE__.Message

  # we need the logger
  require Logger

  @doc """
  Initializes the logger by creating a struct containing options.
  """
  @spec init(options :: Keyword.t) :: level :: atom
  def init(options \\ []) when is_list(options),
    do: %__MODULE__{
      level:        Keyword.get(options, :level, :info),
      include_ip: !!Keyword.get(options, :include_ip, true)
    }

  @doc """
  Called on each request, triggers a log to happen on send.
  """
  @spec call(conn :: Conn.t, level :: atom) :: conn :: Conn.t
  def call(conn, %{ level: :none }),
    do: conn
  def call(conn, %{ level: level } = opts) do
    before_time = :os.timestamp()

    Plug.Conn.register_before_send(conn, fn(conn) ->
      Logger.log(level, fn ->
        diff = :timer.now_diff(:os.timestamp(), before_time)

        conn
        |> Message.create(diff, opts)
        |> Message.join
      end)
      conn
    end)
  end

  # Forward some requests through to the Message module.
  defdelegate create(conn, duration, opts),
    to: Message
  defdelegate join(message),
    to: Message
  defdelegate split(message),
    to: Message

  @doc false
  defmacro __using__(_) do
    import PrePlug, only: [pre_plug: 1]
    quote location: :keep do
      if Module.get_attribute(__MODULE__, :pre_plugs) == nil do
        use PrePlug
      end
      pre_plug Luger
    end
  end

end
