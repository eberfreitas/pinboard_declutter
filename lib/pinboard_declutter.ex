defmodule PinboardDeclutter do
  alias PinboardDeclutter.{API, Updater}

  require Logger

  @workers 16

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
    Logger.configure(level: :warn)

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
    |> Enum.into(Map.new())
  end

  @doc """
  Processes bookmarks using username and password.
  """
  def process(%{username: _, password: _} = auth), do: _process(auth)

  @doc """
  Processes bookmarks using token credential.
  """
  def process(%{token: _} = auth), do: _process(auth)

  @doc """
  Displays help info.
  """
  def process(_) do
    IO.puts("""
    Usage
    -----

    Using your username and password:

        > pinboard_declutter --username johndoe --password s3cr3t

    Using your token:

        > pinboard_declutter --token YOUR_TOKEN_HERE
    """)

    exit(:normal)
  end

  @doc """
  Actual processing of bookmarks. Fetches all bookmarks and put enqueue them
  to processing.
  """
  def _process(auth) do
    Logger.info("Fetching all bookmarks...")

    auth
    |> API.g("/posts/all")
    |> fetch_posts()
    |> enqueue(auth)
  end

  @doc """
  Fetch posts from the Pinboard API response Map after user `parse_response`.
  """
  def fetch_posts({:ok, posts}) do
    posts
  end

  @doc """
  Creates a queue with OPQ to execute and process entries concurrently.
  """
  def enqueue(posts, auth) do
    me = self()
    total = Enum.count(posts)

    {:ok, opq} = OPQ.init(workers: @workers)

    Enum.each(posts, fn post ->
      OPQ.enqueue(opq, fn ->
        Updater.execute(post, auth)

        send(me, {OPQ.info(opq), total})
      end)
    end)

    check()
  end

  @doc """
  Receives messages from the queue processes and exists when there are no more
  items in queue to be processed.
  """
  def check(processed \\ 0) do
    receive do
      {{:normal, {[], []}, workers}, total} ->
        if workers == @workers - 1 do
          progress(total, total)

          exit(:normal)
        else
          progress(processed, total)
          check(processed + 1)
        end

      {{:normal, _, _}, total} ->
        progress(processed, total)
        check(processed + 1)
    end
  end

  @doc """
  Displays a progress bar on screen.
  """
  def progress(curr, total) do
    ProgressBar.render(curr, total)
  end
end
