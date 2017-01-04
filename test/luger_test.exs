defmodule LugerTest do
  use ExUnit.Case
  doctest Luger

  test "logging!" do
    # create base loggers
    opts1 = Luger.init()
    opts2 = Luger.init([ level: :debug ])
    opts3 = Luger.init([ include_ip: false ])

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
      { conn2, opts1 },
      { conn2, opts2 },
      { conn2, opts3 }
    ]

    # map to messages
    msgs = Enum.map(combs, fn({ conn, opts }) ->
      msg = ExUnit.CaptureLog.capture_log(fn ->
        conn
        |> Luger.call(opts)
        |> Plug.Conn.send_resp(200, "")
      end)

      << "\e[", _ :: binary-2, "m\n", _ :: binary-13, rest :: binary >> = msg

      String.replace_trailing(rest, "\n\e[0m", "")
    end)

    # detect messages
    [ msg1, msg2, msg3, msg4, msg5, msg6 ] = msgs

    # verify combinations
    assert(msg1 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg2 =~ ~r/^\[debug\] POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg3 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s$/)
    assert(msg4 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg5 =~ ~r/^\[debug\] POST \/endpoint - 200 - \d+(m|µ)s - 127.0.0.1$/)
    assert(msg6 =~ ~r/^\[info\]  POST \/endpoint - 200 - \d+(m|µ)s$/)

    # detect structs
    [ str1, str2, str3, str4, str5, str6 ] = Enum.map(msgs, &Luger.split/1)

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
end
