defmodule PinboardDeclutter.SiteInfo do

  @moduledoc """
  Parses information from URLs.
  """

  import HTTPoison, only: [get: 3]

  @max_redirects 5

  defstruct url: nil, title: nil, description: nil, action: :update

  def parse(url, action \\ :update, redirects \\ 0)

  def parse(url, _action, @max_redirects), do: %PinboardDeclutter.SiteInfo{url: url, action: :delete}

  def parse(url, action, redirects) do
    url
    |> get([], [ssl: [{:versions, [:'tlsv1.2']}]]) # Broken SSL in Elixir 1.9?
    |> process(url, action, redirects)
  end

  def fix_url(path, original) do
    case URI.parse(path) do
      %{host: nil} ->
        orig = URI.parse(original)
        "#{orig.scheme}://#{orig.host}#{path}"
      %{host: _host} ->
        path
      end
  end

  def process({:ok, %{headers: headers, status_code: code}}, url, _action, redirects) when code in [301, 308] do
    headers
    |> Enum.find(fn elm -> elem(elm, 0) == "Location" end)
    |> elem(1)
    |> fix_url(url)
    |> parse(:replace, redirects + 1)
  end

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

  def process({:error, _}, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :delete}
  end

  def process({:ok, %{status_code: 404}}, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :delete}
  end

  def process(_response, url, _action, _redirects) do
    %PinboardDeclutter.SiteInfo{url: url, action: :pass}
  end

  def get_title([]), do: ""

  def get_title(elms) do
    elms
    |> List.last()
    |> elem(2)
    |> List.first()
    |> to_string()
    |> String.trim()
  end

  def get_description([]), do: ""

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