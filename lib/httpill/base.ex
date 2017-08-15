defmodule HTTPill.Base do
  @moduledoc """
  This is the base module for everything you want to do with HTTPill.

  Here are the methods that actually read your config, make the requests, parse
  the response and handle how this response will be returned.

  ## Creating my own API clients

  You can also `use HTTPill.Base` and customize a lot of functions, creating
  this way your own API client. The options you give when using will be applied
  to `HTTPill.Config` as the default configurations for anyone who uses this
  client.

  Here is an example for you

      defmodule GitHub do
        use HTTPill.Base, base_url: "https://api.github.com"

        def after_process_response(resp) do
          %{resp |
            body: resp.body
                  |> Stream.map(fn ({k, v}) ->
                    {String.to_atom(k), v}
                  end)
                  |> Enum.into(%{})}
        end
      end

  With this module you can make a `GitHub` API calls easily with:

      GitHub.get("/users/octocat/orgs")

  It will make a request to GitHub and return a body with the keys converted to
  atoms. But be careful with that, since atoms are a limited resource.

  ## Overriding functions

  `HTTPill.Base` defines the following list of functions, all of which can be
  overridden (by redefining them). The following list also shows the typespecs
  for these functions and a short description.

      # Called in order to process the url passed to any request method before
      # actually issuing the request.
      @spec before_process_request(binary) :: binary
      def process_url(url)

      # Called to arbitrarily process the request body before sending it with the
      # request.
      @spec process_request_body(term) :: binary
      def process_request_body(body)

      # Called to arbitrarily process the request headers before sending them
      # with the request.
      @spec process_request_headers(term) :: [{binary, term}]
      def process_request_headers(headers)

      # Called to arbitrarily process the request params before sending them
      # with the request.
      @spec process_request_params(map) :: map
      def process_request_params(params)

      # Called to arbitrarily process the request options before sending them
      # with the request.
      @spec process_request_options(keyword) :: keyword
      def process_request_options(options)

      # Called before returning the response body returned by a request to the
      # caller.
      @spec process_response_body(binary) :: term
      def process_response_body(body)

      # Used when an async request is made; it's called on each chunk that gets
      # streamed before returning it to the streaming destination.
      @spec process_response_chunk(binary) :: term
      def process_response_chunk(chunk)

      # Called to process the response headers before returning them to the
      # caller.
      @spec process_headers([{binary, term}]) :: term
      def process_headers(headers)

      # Used to arbitrarily process the status code of a response before
      # returning it to the caller.
      @spec process_status_code(integer) :: term
      def process_status_code(status_code)

  """

  alias HTTPill.AsyncResponse
  alias HTTPill.ConnError
  alias HTTPill.HeaderList
  alias HTTPill.Request
  alias HTTPill.Response

  require Logger

  @type body :: binary | {:form, [{atom, any}]} | {:file, binary}

  defmacro __using__(_) do
    quote do
      @type body :: HTTPill.Base.body

      @doc """
      Starts HTTPill and its dependencies.
      """
      def start, do: :application.ensure_all_started(:httpill)

      def process_url(url) do
        HTTPill.Base.default_process_url(url)
      end

      @spec process_request_body(any) :: body
      def process_request_body(body), do: body

      @spec process_response_body(binary) :: any
      def process_response_body(body), do: body

      @spec process_request_headers(HeaderList.t) :: HeaderList.t
      def process_request_headers(headers), do: headers

      def process_request_params(params), do: params

      def process_request_options(options), do: options

      def process_response_chunk(chunk), do: chunk

      def process_headers(headers), do: headers

      def process_status_code(status_code), do: status_code

      @doc false
      @spec transformer(pid) :: :ok
      def transformer(target) do
        HTTPill.Base.transformer(__MODULE__, target, &process_status_code/1, &process_headers/1, &process_response_chunk/1)
      end

      @doc ~S"""
      Issues an HTTP request with the given method to the given url.

      This function is usually used indirectly by `get/3`, `post/4`, `put/4`, etc

      Args:
        * `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
          `:delete`, etc.)
        * `url` - target url as a binary string or char list
        * `options` - Keyword list of options

      Options:
        * `:body` - request body. See more below
        * `:headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
        * `:params` - an enumerable consisting of two-item tuples that will be appended to the url as query string parameters
        * `:timeout` - timeout to establish a connection, in milliseconds. Default is 8000
        * `:recv_timeout` - timeout used when receiving a connection. Default is 5000
        * `:stream_to` - a PID to stream the response to
        * `:async` - if given `:once`, will only stream one message at a time, requires call to `stream_next`
        * `:proxy` - a proxy to be used for the request; it can be a regular url
          or a `{Host, Port}` tuple
        * `:proxy_auth` - proxy authentication `{User, Password}` tuple
        * `:ssl` - SSL options supported by the `ssl` erlang module
        * `:follow_redirect` - a boolean that causes redirects to be followed
        * `:max_redirect` - an integer denoting the maximum number of redirects to follow

      Body:
        * binary, char list or an iolist
        * map, will be converted to json
        * `{:form, [{K, V}, ...]}` - send a form url encoded
        * `{:file, "/path/to/file"}` - send a file
        * `{:stream, enumerable}` - lazily send a stream of binaries/charlists

      Timeouts can be an integer or `:infinity`

      This function returns `{:ok, response}` or `{:ok, async_response}` if the
      request is successful, `{:error, reason}` otherwise.

      ## Examples

          request(:post, "https://my.website.com",
                  body: "{\"foo\": 3}",
                  headers: [{"Accept", "application/json"}])

      """
      @spec request(atom, binary, Keyword.t) ::
        {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def request(method, url, options \\ []) do
        options = process_request_options(options)

        params =
          options
          |> Keyword.get(:params, nil)
          |> process_request_params()

        url =
          cond do
            !params ->
              url
            URI.parse(url).query ->
              url <> "&" <> URI.encode_query(params)
            true ->
              url <> "?" <> URI.encode_query(params)
          end

        url =
          url
          |> to_string()
          |> process_url()
        original_body = Keyword.get(options, :body, "")
        headers =
          options
          |> Keyword.get(:headers, [])
          |> HeaderList.normalize()
          |> put_content_type(original_body)
          |> process_request_headers()
        body =
          original_body
          |> encode_request_body(HeaderList.get(headers, "Content-Type"))
          |> process_request_body()
        HTTPill.Base.request(__MODULE__,
                             %Request{
                               options: options,
                               body: body,
                               headers: headers,
                               method: method,
                               params: params,
                               url: url
                             },
                             &process_status_code/1,
                             &process_headers/1,
                             &process_response_body/1)
      end

      defp put_content_type(headers, body) when is_map(body) do
        HeaderList.put(headers, "Content-Type", "application/json; charset=UTF-8")
      end
      defp put_content_type(headers, _) do
        headers
      end

      defp encode_request_body(body, nil) do
        body
      end
      defp encode_request_body(body, content_type) when is_map(body) do
        if String.contains?(content_type, "json") do
          case Poison.encode(body) do
            {:ok, json} -> json
            {:error, _} -> body
          end
        else
          body
        end
      end
      defp encode_request_body(body, _content_type) do
        body
      end

      @doc """
      Issues an HTTP request with the given method to the given url, raising an
      exception in case of failure.

      `request!/3` works exactly like `request/3` but it returns just the
      response in case of a successful request, raising an exception in case the
      request fails.
      """
      @spec request!(atom, binary, Keyword.t) :: Response.t
      def request!(method, url, options \\ []) do
        case request(method, url, options) do
          {:ok, response} ->
            response
          {:error, %ConnError{reason: reason}} ->
            raise ConnError, reason: reason
        end
      end

      @doc """
      Issues a GET request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec get(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def get(url, options \\ []), do: request(:get, url, options)

      @doc """
      Issues a GET request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec get!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def get!(url, options \\ []), do: request!(:get, url, options)

      @doc """
      Issues a PUT request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec put(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t } | {:error, ConnError.t}
      def put(url, options \\ []), do: request(:put, url, options)

      @doc """
      Issues a PUT request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec put!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def put!(url, options \\ []), do: request!(:put, url, options)

      @doc """
      Issues a HEAD request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec head(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def head(url, options \\ []), do: request(:head, url, options)

      @doc """
      Issues a HEAD request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec head!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def head!(url, options \\ []), do: request!(:head, url, options)

      @doc """
      Issues a POST request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec post(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def post(url, options \\ []), do: request(:post, url, options)

      @doc """
      Issues a POST request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec post!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def post!(url, options \\ []), do: request!(:post, url, options)

      @doc """
      Issues a PATCH request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec patch(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def patch(url, options \\ []), do: request(:patch, url, options)

      @doc """
      Issues a PATCH request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec patch!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def patch!(url, options \\ []), do: request!(:patch, url, options)

      @doc """
      Issues a DELETE request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec delete(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def delete(url, options \\ []), do: request(:delete, url, options)

      @doc """
      Issues a DELETE request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec delete!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def delete!(url, options \\ []), do: request!(:delete, url, options)

      @doc """
      Issues an OPTIONS request to the given url.

      Returns `{:ok, response}` if the request is successful, `{:error, reason}`
      otherwise.

      See `request/3` for more detailed information.
      """
      @spec options(binary, Keyword.t) :: {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def options(url, options \\ []), do: request(:options, url, options)

      @doc """
      Issues a OPTIONS request to the given url, raising an exception in case of
      failure.

      If the request does not fail, the response is returned.

      See `request!/3` for more detailed information.
      """
      @spec options!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def options!(url, options \\ []), do: request!(:options, url, options)

      @doc """
      Requests the next message to be streamed for a given
      `HTTPill.AsyncResponse`.

      See `request!/3` for more detailed information.
      """
      @spec stream_next(AsyncResponse.t) :: {:ok, AsyncResponse.t} | {:error, ConnError.t}
      def stream_next(resp = %AsyncResponse{ id: id }) do
        case :hackney.stream_next(id) do
          :ok -> {:ok, resp}
          err -> {:error, %ConnError{reason: "stream_next/1 failed", id: id}}
        end
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  @doc false
  def transformer(module, target, process_status_code, process_headers, process_response_chunk) do
    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        send target, %HTTPill.AsyncStatus{id: id, code: process_status_code.(code)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
      {:hackney_response, id, {:headers, headers}} ->
        send target, %HTTPill.AsyncHeaders{id: id, headers: process_headers.(headers)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
      {:hackney_response, id, :done} ->
        send target, %HTTPill.AsyncEnd{id: id}
      {:hackney_response, id, {:error, reason}} ->
        send target, %ConnError{id: id, reason: reason}
      {:hackney_response, id, {redirect, to, headers}} when redirect in [:redirect, :see_other] ->
        send target, %HTTPill.AsyncRedirect{id: id, to: to, headers: process_headers.(headers)}
      {:hackney_response, id, chunk} ->
        send target, %HTTPill.AsyncChunk{id: id, chunk: process_response_chunk.(chunk)}
        transformer(module, target, process_status_code, process_headers, process_response_chunk)
    end
  end

  @doc false
  def default_process_url(url) do
    case url |> String.slice(0, 12) |> String.downcase do
      "http://" <> _ -> url
      "https://" <> _ -> url
      "http+unix://" <> _ -> url
      _ -> "http://" <> url
    end
  end

  defp build_hackney_options(module, options) do
    timeout = Keyword.get options, :timeout
    recv_timeout = Keyword.get options, :recv_timeout
    stream_to = Keyword.get options, :stream_to
    async = Keyword.get options, :async
    proxy = Keyword.get options, :proxy
    proxy_auth = Keyword.get options, :proxy_auth
    ssl = Keyword.get options, :ssl
    follow_redirect = Keyword.get options, :follow_redirect
    max_redirect = Keyword.get options, :max_redirect

    hn_options = Keyword.get options, :hackney, []

    hn_options = if timeout, do: [{:connect_timeout, timeout} | hn_options], else: hn_options
    hn_options = if recv_timeout, do: [{:recv_timeout, recv_timeout} | hn_options], else: hn_options
    hn_options = if proxy, do: [{:proxy, proxy} | hn_options], else: hn_options
    hn_options = if proxy_auth, do: [{:proxy_auth, proxy_auth} | hn_options], else: hn_options
    hn_options = if ssl, do: [{:ssl_options, ssl} | hn_options], else: hn_options
    hn_options = if follow_redirect, do: [{:follow_redirect, follow_redirect} | hn_options], else: hn_options
    hn_options = if max_redirect, do: [{:max_redirect, max_redirect} | hn_options], else: hn_options

    hn_options =
      if stream_to do
        async_option = case async do
          nil   -> :async
          :once -> {:async, :once}
        end
        [async_option, {:stream_to, spawn_link(module, :transformer, [stream_to])} | hn_options]
      else
        hn_options
      end

    hn_options
  end

  @doc false
  @spec request(atom, Request.t, fun, fun, fun) ::
    {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
  def request(module, request, process_status_code, process_headers, process_body) do
    hn_options = build_hackney_options(module, request.options)

    Logger.debug(["HTTP request started - ",
                  "module ", inspect(module), " - ",
                  "method ", inspect(request.method), ?\s,
                  request.url])
    Logger.debug(["HTTP request body: ", inspect(request.body)])
    start = :os.system_time(:milli_seconds)

    result = case do_request(request, hn_options) do
      {:ok, status_code, headers} ->
        response(process_status_code, process_headers, process_body, status_code, headers, "", request)
      {:ok, status_code, headers, client} ->
        case :hackney.body(client) do
          {:ok, body} -> response(process_status_code, process_headers, process_body, status_code, headers, body, request)
          {:error, reason} -> {:error, %ConnError{reason: reason} }
        end
      {:ok, id} -> { :ok, %HTTPill.AsyncResponse{ id: id } }
      {:error, reason} -> {:error, %ConnError{reason: reason}}
    end

    duration = :os.system_time(:milli_seconds) - start
    Logger.debug(["HTTP request ended - ",
                  "module ", inspect(module), " - ",
                  "method ", inspect(request.method), ?\s,
                  request.url, ?\s,
                  "time=", inspect(duration), "ms"])

    result
  end

  defp do_request(%Request{body: {:stream, enumerable}} = request, hn_options) do
    with {:ok, ref} <- :hackney.request(request.method,
                                        request.url,
                                        request.headers,
                                        :stream,
                                        hn_options) do
      failures = Stream.transform(enumerable, :ok, fn
        _, :error -> {:halt, :error}
        bin, :ok  -> {[], :hackney.send_body(ref, bin)}
        _, error  -> {[error], :error}
      end) |> Enum.into([])

      case failures do
        [] ->
          :hackney.start_response(ref)
        [failure] ->
          failure
      end
    end
  end

  defp do_request(request, hn_options) do
    :hackney.request(request.method,
                     request.url,
                     request.headers,
                     request.body,
                     hn_options)
  end

  defp decode_response_body(body, nil) do
    body
  end
  defp decode_response_body(body, accepts) do
    if String.contains?(accepts, "json") do
      case Poison.decode(body) do
        {:ok, json} -> json
        {:error, _} -> body
      end
    else
      body
    end
  end

  defp response(process_status_code, process_headers, process_response_body, status_code, headers, body, request) do
    body =
      body
      |> decode_response_body(HeaderList.get(request.headers, "Accepts"))
      |> process_response_body.()
    {:ok, %Response{
      status_code: process_status_code.(status_code),
      headers: process_headers.(headers),
      body: body,
      request: request
    }}
  end
end

