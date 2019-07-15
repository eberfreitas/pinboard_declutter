defmodule PinboardDeclutter do

  alias PinboardDeclutter.{API, Updater}

  require Logger

  @moduledoc """
  # Pinboard Declutter

  Pinboard Declutter is a small tool that goes through your bookmarks...

  - Removing dead links
  - Updating redirects
  - Updating titles and descriptions
  """

  @doc """
  Entry point for our script. Receives a list with user's credentials:

      iex> PinboardDeclutter.main(["--username", "johndoe", "--password", "s3cr3t"])

      iex> PinboardDeclutter.main(["--token", "YOURTOKEN"])
  """
  def main(argv) do
    argv
    |> parse_args
    |> process()
  end

  @doc """
  Parses CLI args and sets up a map containing the data.

      iex> PinboardDeclutter.parse_args(["--username", "johndoe", "--password", "s3cr3t"])
      %{username: "johndoe", password: "s3cr3t"}
  """
  def parse_args(argv) do
    OptionParser.parse(argv, strict: [username: :string, password: :string, token: :string])
    |> elem(0)
    |> Enum.into(Map.new)
  end

  @doc """
  Main process of our script.
  """
  def process(%{username: _, password: _} = auth), do: _process(auth)
  def process(%{token: _} = auth), do: _process(auth)
  def process(_) do
    IO.puts """
    Usage
    -----

    Using your username and password:

        > pinboard_declutter --username johndoe --password s3cr3t

    Using your token:

        > pinboard_declutter --token YOUR_TOKEN_HERE
    """

    exit(:normal)
  end

  def _process(auth) do
    Logger.info("Fetching all bookmarks...")

    auth
    |> API.g("/posts/all")
    |> fetch_posts()
    |> enqueue(auth)
  end

  def enqueue(posts, auth) do
    {:ok, opq} = OPQ.init

    Enum.each(posts, fn post ->
      OPQ.enqueue(opq, fn ->
        Updater.execute(post, auth)
      end)
    end)

    run(OPQ.info(opq), opq)
  end

  def run({:normal, {[], []}, _}, _opq) do
    Process.sleep(2000)

    exit(:normal)
  end

  def run({:normal, _queue, _}, opq) do
    Process.sleep(1000)

    run(OPQ.info(opq), opq)
  end

  @doc """
  Fetch posts from the Pinboard API response Map after user `parse_response`.
  """
  def fetch_posts({:ok, posts}) do
    posts
  end
end
