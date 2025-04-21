defmodule Luger.Message do
  @moduledoc """
  This module contains functions to create an format log messages using Luger.

  This is separated out as it makes testing your logging easier as you can use
  the `split/1` function to convert your log into a struct.
  """
  defstruct [
    :method,
    :path,
    :status,
    :duration,
    :ip_address
  ]

  # add the opaque type
  @opaque t :: %__MODULE__{}

  @doc """
  Creates a Message struct from a connection and duration.
  """
  @spec create(Conn.t(), integer, Luger.t()) :: Message.t()
  def create(%Plug.Conn{} = conn, duration, %Luger{include_ip: include})
      when is_integer(duration) do
    %{method: method, request_path: path, status: status} = conn

    %__MODULE__{
      method: method,
      path: path,
      status: status,
      duration: duration,
      ip_address: (include && conn.remote_ip) || nil
    }
  end

  @doc """
  Joins a Message struct into a binary log message.
  """
  @spec join(Message.t()) :: binary
  def join(%__MODULE__{method: m, path: p, status: s, duration: d} = msg) do
    "#{m} #{p} - #{join_status(s)} - #{join_duration(d)}" <>
      case msg.ip_address do
        nil -> ""
        val -> " - #{join_ip(val)}"
      end
  end

  # Converts a duration to a human readable format.
  defp join_duration(diff) when diff > 1000,
    do: "#{round(diff / 1000)}ms"

  defp join_duration(diff),
    do: "#{diff}µs"

  # Converts an IP structure to a binary.
  defp join_ip({a, b, c, d}),
    do: "#{a}.#{b}.#{c}.#{d}"

  defp join_ip(ip) when is_binary(ip),
    do: ip

  # Converts a status to a binary.
  defp join_status(nil),
    do: "unset"

  defp join_status(val),
    do: to_string(val)

  @doc """
  Splits a log message back into a Message struct.
  """
  @spec split(binary) :: Message.t()
  def split(message) when is_binary(message) do
    [route, status, duration | ip_address] = String.split(message, " - ")
    [path, method | _] = route |> String.split(" ") |> Enum.reverse()

    %__MODULE__{
      method: method,
      path: path,
      status: split_status(status),
      duration: split_duration(duration),
      ip_address: split_ip(ip_address)
    }
  end

  # Converts a binary duration to an integer.
  defp split_duration(duration) do
    duration
    |> String.replace_suffix("ms", "")
    |> String.replace_suffix("µs", "")
    |> String.to_integer()
  end

  # Converts a binary IP split to a Tuple.
  defp split_ip([]),
    do: nil

  defp split_ip([ip]) do
    ip
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end

  # Converts a status split to an integer (if there is one).
  defp split_status(<<char, _rest::binary>> = status) when char in ?0..?9,
    do: String.to_integer(status)

  defp split_status(_status),
    do: nil
end
