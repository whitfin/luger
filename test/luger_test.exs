defmodule LugerTest do
  use ExUnit.Case
  doctest Luger

  # Tests happy path for logging and various option combinations and how they
  # affect the message being logged and the level it's logged under.
  test "base logging" do
    # create base loggers
    opts1 = Luger.init()
    opts2 = Luger.init([ level: :debug ])
    opts3 = Luger.init([ include_ip: false ])
    opts4 = Luger.init([ level: :none ])

    # create a base connection for testing
    base = Plug.Adapters.Test.Conn.conn(%Plug.Conn{ }, :post, "/endpoint", %{ })

    # test with and without a binary ip
    conn1 = %Plug.Conn{ base | remote_ip: "127.0.0.1" }
    conn2 = base

    # define our logging combinations
    combs = [
      { conn1, opts1 },
      { conn1, opts2 },
      { conn1, opts3 },
      { conn1, opts4 },
      { conn2, opts1 },
      { conn2, opts2 },
      { conn2, opts3 },
      { conn2, opts4 }
    ]

    # map to messages
    msgs = Enum.map(combs, fn({ conn, opts }) ->
      msg = ExUnit.CaptureLog.capture_log(fn ->
        conn
        |> Luger.call(opts)
        |> Plug.Conn.send_resp(200, "")
      end)

      with << "\e[", _ :: binary-2, "m\n", _ :: binary-13, rest :: binary >> <- msg do
        String.replace_trailing(rest, "\n\e[0m", "")
      end
    end)

    # detect messages
    [ msg1, msg2, msg3, msg4, msg5, msg6, msg7, msg8 ] = msgs

    # verify combinations
    assert(msg1 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg2 =~ ~r/^\[debug\] POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg3 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s$/)
    assert(msg4 == "")
    assert(msg5 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg6 =~ ~r/^\[debug\] POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg7 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s$/)
    assert(msg8 == "")

    # detect structs
    [ str1, str2, str3, str4, str5, str6 ] =
      msgs
      |> Enum.filter(&String.length(&1) > 0)
      |> Enum.map(&Luger.split/1)

    # define a validatior
    validate = fn(str, ip) ->
      assert(str.method == "POST")
      assert(str.path == "/endpoint")
      assert(str.status == 200)
      assert(is_number(str.duration))
      assert(str.ip_address == ip)
    end

    # verify converstion back to structs
    validate.(str1, { 127, 0, 0, 1 })
    validate.(str2, { 127, 0, 0, 1 })
    validate.(str3, nil)
    validate.(str4, { 127, 0, 0, 1 })
    validate.(str5, { 127, 0, 0, 1 })
    validate.(str6, nil)
  end

  # Verifies duration formatting can also handle millisecond formatting rather
  # than just measuring in microsecond durations (which is confusing).
  test "duration formatting" do
    # create base logger
    opts = Luger.init()

    # create a base connection for testing
    base = Plug.Adapters.Test.Conn.conn(%Plug.Conn{ }, :post, "/endpoint", %{ })

    # create a Luger message
    struct =
      base
      |> Plug.Conn.send_resp(200, "")
      |> Luger.Message.create(5000, opts)

    # join the struct
    joined = Luger.join(struct)

    # verify the message has millis formatting
    assert(joined == "POST /endpoint - 200 - 5ms - 127.0.0.1")
  end

  # Verifies that unset status inside connections is handled and logged as unset.
  # This should never happen in practice, it's just a safetynet for manual use.
  test "status formatting" do
    # create base logger
    opts = Luger.init()

    # create a base connection for testing
    base = Plug.Adapters.Test.Conn.conn(%Plug.Conn{ }, :post, "/endpoint", %{ })

    # create connections
    conn1 = base
    conn2 = Plug.Conn.send_resp(base, 200, "")

    # create a Luger message
    struct1 = Luger.Message.create(conn1, 500, opts)
    struct2 = Luger.Message.create(conn2, 500, opts)

    # join the structs
    joined1 = Luger.join(struct1)
    joined2 = Luger.join(struct2)

    # verify the message has correct formatting
    assert(joined1 == "POST /endpoint - unset - 500µs - 127.0.0.1")
    assert(joined2 == "POST /endpoint - 200 - 500µs - 127.0.0.1")

    # convert them back into structs
    struct3 = Luger.split(joined1)
    struct4 = Luger.split(joined2)

    # verify we got the base back
    assert(struct3 == struct1)
    assert(struct4 == struct2)
  end
end
