defmodule PinboardDeclutter.SiteInfo do
  @moduledoc """
  Parses information from URLs. Extracts page title and description from HTML.
  """

  import HTTPoison, only: [get: 3]

  @max_redirects 5

  defstruct url: nil, title: nil, description: nil, action: :update

  @doc "Function head."
  def parse(url, action \\ :update, redirects \\ 0)

  @doc """
  Called once we reach the maximum of redirects trying to resolve a URL.
  """
  def parse(url, _action, @max_redirects),
    do: %PinboardDeclutter.SiteInfo{url: url, action: :delete}

  @doc """
  Tries to parse a URL a returns a full filled struct.
  """
  def parse(url, action, redirects) do
    try do
      url
      # Broken SSL in Elixir 1.9?
      |> get([], ssl: [{:versions, [:"tlsv1.2"]}])
      |> process(url, action, redirects)
    rescue
      CaseClauseError -> %PinboardDeclutter.SiteInfo{url: url, action: :pass}
    end
  end

  @doc """
  Sometimes when redirecting servers will informe a relative path. This method
  tries to fix the URL when that happens.
  """
  def fix_url(path, original) do
    case URI.parse(path) do
      %{host: nil} ->
        orig = URI.parse(original)
        "#{orig.scheme}://#{orig.host}#{path}"

      %{host: _host} ->
        path
    end
  end

  @doc """
  If we get a redirect (http status codes 301 or 308), we extract the new URL
  and try to process it again.
  """
  def process({:ok, %{headers: headers, status_code: code}}, url, _action, redirects)
      when code in [301, 308] do
    headers
    |> Enum.find(fn elm -> String.downcase(elem(elm, 0)) == "location" end)
    |> elem(1)
    |> fix_url(url)
    |> parse(:replace, redirects + 1)
  end

  @doc """
  Returns a struct for a successfully requested page (http status 200).
  """
  def process({:ok, %{body: body, status_code: 200}}, url, action, _redirects) do
    title =
      body
      |> Floki.find("head title")
      |> get_title()

    description =
      body
      |> Floki.find("meta[name=description]")
      |> get_description()

    %PinboardDeclutter.SiteInfo{title: title, description: description, url: url, action: action}
  end

  @doc "Process a URL when the request has failed."
  def process({:error, _}, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :delete}
  end

  @doc "Process a URL when the response is 404"
  def process({:ok, %{status_code: 404}}, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :delete}
  end

  @doc """
  Catch all process to edge cases. Passes an action of `pass` meaning this
  element will not be processed in anyway by the system.
  """
  def process(_response, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :pass}
  end

  @doc "Return empty string when empty list."
  def get_title([]), do: ""

  @doc """
  Receives a list from Floki and extracts the title.
  """
  def get_title(elms) do
    elms
    |> List.last()
    |> elem(2)
    |> List.first()
    |> to_string()
    |> String.trim()
  end

  @doc "Return empty string when empty list."
  def get_description([]), do: ""

  @doc """
  Receives a list from Floki and extracts the description.
  """
  def get_description(elms) do
    elms
    |> List.last()
    |> elem(1)
    |> Enum.find(fn elm -> elem(elm, 0) == "content" end)
    |> elem(1)
    |> to_string()
    |> String.trim()
  end
end
