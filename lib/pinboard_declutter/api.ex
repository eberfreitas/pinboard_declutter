defmodule PinboardDeclutter.API do
  use HTTPoison.Base

  require Logger

  @moduledoc """
  Interface with the Pinboard API using HTTPoison.Base. Always uses JSON
  for formatting.
  """

  @endpoint "https://api.pinboard.in/v1"

  @doc """
  Performs a GET request to the api using username and password credentials.
  """
  def g(%{username: username, password: password}, path) do
    Logger.debug("GET: #{path}")

    credentials = Base.encode64("#{username}:#{password}")
    auth = [{"Authorization", "Basic #{credentials}"}]

    get(path, auth) |> parse_response()
  end

  @doc """
  Performs a GET request to the api using token credential.
  """
  def g(%{token: token}, path) do
    path = path <> get_separator(path) <> "auth_token=" <> token

    Logger.debug("GET: #{path}")

    get(path) |> parse_response()
  end

  @doc """
  Transforms the JSON response from Pinboard API to a Map.
  """
  def parse_response({:ok, %{body: body, status_code: 200}}) do
    Jason.decode(body)
  end

  @doc """
  Halts the system if we can't get a response from the Pinboard API.
  """
  def parse_response(_request) do
    msg = """

    !!! Could not connect to Pinboard API. Check your credentials or try it later.

    """

    Logger.warn(msg)
    IO.puts(msg)

    exit(:normal)
  end

  @impl true
  def process_url(url) do
    @endpoint <> url <> get_separator(url) <> "format=json"
  end

  @doc """
  Decides what will be the "glue" to append query strings to the path.
  """
  def get_separator(url) do
    if String.contains?(url, "?"), do: "&", else: "?"
  end
end
