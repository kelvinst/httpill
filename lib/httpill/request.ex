defmodule HTTPill.Request do
  @moduledoc """
  Represents an HTTP request and carries all the information needed to issue
  one.

  To get a new request with correctly handled data, please give a check on the
  `new/5` function.
  """

  defstruct [:method, :params, :url, body: "", options: [], headers: []]

  alias HTTPill.Config
  alias HTTPill.HeaderList
  alias HTTPill.Request

  @type t :: %Request{
    body: term,
    headers: HTTPill.HeaderList.t,
    method: atom,
    options: list,
    params: term,
    url: binary
  }

  @doc """
  Creates a brand new request, correctly handling url and other configs, making
  it ready to be issued.

  Here is the list of arg you must give:

    - `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
      `:delete`, etc.)
    - `url` - target url as a binary string or char list
    - `options` - Keyword list of options, see the available options below
    - `before_process` - a function to customize the request before building it
    - `after_process` - a function to customize the request after building it

  Options:
    - `:body` - request body
      - a binary, char list or an iolist
      - a map, which will be converted to json
      - `{:form, [{K, V}, ...]}` - send a form url encoded
      - `{:file, "/path/to/file"}` - send a file
      - `{:stream, enumerable}` - lazily send a stream of binaries/charlists
    - `:headers` - HTTP headers as an orddict (e.g.,
    `[{"Accept", "application/json"}]`)
    - `:params` - an enumerable consisting of two-item tuples that will be
    appended to the url as query string parameters
    - `:timeout` - timeout to establish a connection, in milliseconds.
    Default is 8000
    - `:recv_timeout` - timeout used when receiving a connection.
    Default is 5000
    - `:stream_to` - a PID to stream the response to
    - `:async` - if given `:once`, will only stream one message at a time,
    requires call to `stream_next`
    - `:proxy` - a proxy to be used for the request; it can be a regular
    url or a `{Host, Port}` tuple
    - `:proxy_auth` - proxy authentication `{User, Password}` tuple
    - `:ssl` - SSL options supported by the `ssl` erlang module
    - `:follow_redirect` - a boolean that causes redirects to be followed
    - `:max_redirect` - an integer denoting the maximum number of
    redirects to follow

  Timeouts can be an integer or `:infinity`
  """
  @spec new(atom, binary, Keyword.t, function, function, Config.t) :: t
  def new(method, url, options, before_process, after_process, config) do
    Request
    |> struct([
      {:method, method},
      {:url, url},
      {:options, options} |
      options
    ])
    |> before_process.()
    |> handle_url(config)
    |> handle_headers()
    |> handle_body()
    |> after_process.()
  end

  defp handle_url(%Request{} = request, %Config{base_url: base}) do
    url =
      request
      |> get_url_with_params()
      |> to_string()
      |> concat_base_url(base)
      |> concat_url_protocol()
    %{request | url: url}
  end

  defp get_url_with_params(%Request{url: url, params: params}) do
    cond do
      !params ->
        url
      URI.parse(url).query ->
        url <> "&" <> URI.encode_query(params)
      true ->
        url <> "?" <> URI.encode_query(params)
    end
  end

  defp concat_base_url(url, nil), do: url
  defp concat_base_url(url, base), do: "#{base}/#{url}"

  defp concat_url_protocol(url) do
    url
    |> String.slice(0, 12)
    |> String.downcase
    |> case do
      "http://" <> _ -> url
      "https://" <> _ -> url
      "http+unix://" <> _ -> url
      _ -> "http://" <> url
    end
  end

  defp handle_headers(%Request{} = request) do
    headers =
      request.headers
      |> HeaderList.normalize()
      |> put_content_type(request.body)
    %{request | headers: headers}
  end

  defp put_content_type(headers, body) when is_map(body) do
    HeaderList.put(headers, "Content-Type", "application/json; charset=UTF-8")
  end
  defp put_content_type(headers, _) do
    headers
  end

  defp handle_body(%Request{} = req) do
    body = encode_body(req.body, HeaderList.get(req.headers, "Content-Type"))
    %{req | body: body}
  end

  defp encode_body(body, nil) do
    body
  end
  defp encode_body(body, content_type) when is_map(body) do
    if String.contains?(content_type, "json") do
      case Poison.encode(body) do
        {:ok, json} -> json
        {:error, _} -> body
      end
    else
      body
    end
  end
  defp encode_body(body, _content_type) do
    body
  end
end

