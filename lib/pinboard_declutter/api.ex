defmodule PinboardDeclutter.API do

  use HTTPoison.Base

  require Logger

  @moduledoc """
  Interface with the Pinboard API using HTTPoison.Base. Always uses JSON
  for formatting.
  """

  @endpoint "https://api.pinboard.in/v1"

  def g(%{username: username, password: password}, path) do
    Logger.info("GET: #{path}")

    credentials = Base.encode64("#{username}:#{password}")
    auth = [{"Authorization", "Basic #{credentials}"}]

    get(path, auth) |> parse_response()
  end

  def g(%{token: token}, path) do
    path = path <> get_separator(path) <> "auth_token=" <> token

    Logger.info("GET: #{path}")

    get(path) |> parse_response()
  end

  @doc """
  Transforms the XML response from Pinboard API to a Map.
  """
  def parse_response({:ok, %{body: body, status_code: 200}}) do
    Jason.decode(body)
  end

  @doc """
  Halts the system if we can't get a response from the Pinboard API.
  """
  def parse_response(request) do
    IO.puts """

    !!! Could not connect to Pinboard API. Check your credentials or try it later.

    """

    System.halt(2)
  end

  def process_url(url) do
    @endpoint <> url <> get_separator(url) <> "format=json"
  end

  def get_separator(url) do
    if String.contains?(url, "?"), do: "&", else: "?"
  end
end