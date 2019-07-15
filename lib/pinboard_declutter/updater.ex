defmodule PinboardDeclutter.Updater do

  alias PinboardDeclutter.{API, SiteInfo}

  require Logger

  @doc """
  Receives one item from the bookmarks API and executes the update on it.
  """
  def execute(post, auth) do
    post
    |> get_site_info()
    |> process(post, auth)
  end

  @doc """
  Produces the SiteInfo struct related to the URL.
  """
  def get_site_info(%{"href" => href}) do
    SiteInfo.parse(href)
  end

  @doc """
  Handles the process when we need to delete an entry.
  """
  def process(%{action: :delete} = info, original, auth) do
    Logger.info("Deleting #{original["href"]}")

    API.g(auth, "/posts/delete?#{URI.encode_query([url: original["href"]])}")
    |> log(info)
  end

  @doc """
  Skips processing for `action: :pass` entries.
  """
  def process(%{action: :pass}, original, _auth) do
    Logger.info("Passing on #{original["href"]}")
  end

  @doc """
  Replaces the entry with an updated version. Useful when there are http
  redirects from the original URL.
  """
  def process(%{action: :replace} = info, original, auth) do
    Logger.info("Replacing #{original["href"]} with #{info.url}")

    API.g(auth, "/posts/delete?#{URI.encode_query([url: original["href"]])}")

    query_string = make_query_string(info, original)

    API.g(auth, "/posts/add?#{query_string}") |> log(info)
  end

  @doc """
  Just updates the info from and existing URL.
  """
  def process(%{action: :update} = info, original, auth) do
    if info.title != original["description"] || info.description != original["extended"] do
      Logger.info("Updating #{original["href"]}")

      query_string = make_query_string(info, original)

      API.g(auth, "/posts/add?#{query_string}") |> log(info)
    else
      Logger.info("Skipping on #{original["href"]}")
      nil
    end
  end

  @doc """
  Builds a valid query string from new data and old.
  """
  def make_query_string(info, original) do
    [
      url: info.url,
      description: info.title,
      extended: info.description,
      tags: original["tags"],
      shared: original["shared"],
      toread: original["toread"],
      dt: original["time"]
    ]
    |> URI.encode_query()
  end

  @doc """
  Helper function to log successful API requests
  """
  def log({:ok, _}, info) do
    Logger.info("Successfully processed #{info.url}")
  end

  @doc """
  Helper function to log failed API requests
  """
  def log(_response, info) do
    Logger.warn("Error saving #{info.url}")
  end
end