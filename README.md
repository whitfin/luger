# Luger
[![Build Status](https://img.shields.io/travis/whitfin/luger.svg)](https://travis-ci.org/whitfin/luger) [![Coverage Status](https://img.shields.io/coveralls/whitfin/luger.svg)](https://coveralls.io/github/whitfin/luger) [![Hex.pm Version](https://img.shields.io/hexpm/v/luger.svg)](https://hex.pm/packages/luger) [![Documentation](https://img.shields.io/badge/docs-latest-yellowgreen.svg)](https://hexdocs.pm/luger/)

Luger is a super simple logging plug for Elixir which logs status codes and IP addresses as well as the route. I basically made it into a module rather than rolling my own logger in every project (seeing as the built-in Plug logger really isn't very useful).

Includes bindings using [pre_plug](https://github.com/whitfin/pre_plug) to ensure that logs are fired even in case of error states.

## Installation

As of v1.0.0, Luger is available on [Hex](https://hex.pm/). You can install the package via:

Add luger to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:luger, "~> 1.0"}]
end
```

Ensure luger is started before your application:

```elixir
def application do
  [applications: [:luger]]
end
```

## Usage

Super easy, just like any other plug - just drop it into your router.

You can use `plug Luger`, but if you use `use Luger` you get some additional safety bindings.

```elixir
defmodule PlugTest.Router do
  # import Conn
  import Plug.Conn

  # pull in any Plug dependencies
  use Plug.ErrorHandler
  use Plug.Router

  # add the logger
  use Luger # or `plug Luger`

  # plug requirements
  plug :match
  plug :dispatch

  get "/" do
    raise Plug.BadRequestError
  end

  defp handle_errors(conn, _) do
    send_resp(conn, conn.status, "Something went wrong!")
  end
end
```

## Options

There are a couple of options you can use to customize the output.

The values shown below are the default values:

```elixir
plug Luger,
  include_ip: true,  # ignore ip address (useful if local only)
  level: :info       # the log message logging level
```
