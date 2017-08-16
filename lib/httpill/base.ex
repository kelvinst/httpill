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

      # Called before and after processing the request info for any request
      def before_process_request(request)
      def after_process_request(request)

      # Called before and after processing the response info for any request
      def before_process_response(response)
      def after_process_response(response)

      # Called before and after the response for any async requests
      def before_process_any_async_response(response)
      def after_process_any_async_response(response)

  """

  alias HTTPill.AsyncResponse
  alias HTTPill.AsyncStatus
  alias HTTPill.AsyncHeaders
  alias HTTPill.AsyncChunk
  alias HTTPill.AsyncRedirect
  alias HTTPill.AsyncEnd
  alias HTTPill.Config
  alias HTTPill.ConnError
  alias HTTPill.Request
  alias HTTPill.Response
  alias HTTPill.StatusError

  require Logger

  defmacro __using__(opts) do
    quote do
      @type any_async_response ::
        AsyncResponse.t |
        AsyncStatus.t |
        AsyncHeaders.t |
        AsyncChunk.t |
        AsyncRedirect.t |
        AsyncEnd.t

      @doc """
      Returns the configuration for this module.
      """
      @spec config() :: Config.t
      def config, do: HTTPill.Base.config(__MODULE__, unquote(opts))

      @doc """
      Starts HTTPill and its dependencies.
      """
      def start, do: :application.ensure_all_started(:httpill)

      @spec before_process_request(Request.t) :: Request.t
      def before_process_request(request), do: request

      @spec after_process_request(Request.t) :: Request.t
      def after_process_request(request), do: request

      @spec before_process_response(Response.t) :: Response.t
      def before_process_response(response), do: response

      @spec after_process_response(Response.t) :: Response.t
      def after_process_response(response), do: response

      @spec process_any_async_response(any_async_response) :: any_async_response
      def process_any_async_response(response), do: response

      @doc false
      @spec transformer(pid) :: :ok
      def transformer(target) do
        HTTPill.Base.transformer(__MODULE__,
                                 target,
                                 &process_any_async_response/1)
      end

      @doc """
      Issues an HTTP request with the given method to the given url.

      This function is used indirectly by `get/2`, `post/2`, `put/2`, etc

      For information about the options, go check the `HTTPill.Request` docs.

      The return of this function depends on the `response_handling_method`
      configured. Check `HTTPill.Config` to check the available options and how
      to set them.

      ## Examples

          request(:post, "https://my.website.com",
                  body: "{\"foo\": 3}",
                  headers: [{"Accept", "application/json"}])

      """
      @spec request(atom, binary, Keyword.t) ::
        {:ok, Response.t | AsyncResponse.t} | {:error, ConnError.t}
      def request(method, url, options \\ []) do
        request = Request.new(method,
                              url,
                              options,
                              config(),
                              &before_process_request/1,
                              &after_process_request/1)
        HTTPill.Base.request(__MODULE__,
                             request,
                             config(),
                             &before_process_response/1,
                             &after_process_response/1)
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
          {:status_error, response} ->
            raise StatusError, response: response
          {:error, %ConnError{reason: reason}} ->
            raise ConnError, reason: reason
          %ConnError{reason: reason} ->
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
  def config(module, opts) do
    struct(Config,
           Keyword.merge(opts, Application.get_env(:httpill, module, [])))
  end

  @doc false
  def transformer(module, target, process) do
    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        send target, process.(%AsyncStatus{id: id, code: code})
        transformer(module, target, process)
      {:hackney_response, id, {:headers, headers}} ->
        send target, process.(%AsyncHeaders{id: id, headers: headers})
        transformer(module, target, process)
      {:hackney_response, id, :done} ->
        send target, process.(%AsyncEnd{id: id})
      {:hackney_response, id, {:error, reason}} ->
        send target, %ConnError{id: id, reason: reason}
      {:hackney_response, id, {redirect, to, headers}}
      when redirect in [:redirect, :see_other] ->
        send target, process.(%AsyncRedirect{id: id, to: to, headers: headers})
      {:hackney_response, id, chunk} ->
        send target, process.(%AsyncChunk{id: id, chunk: chunk})
        transformer(module, target, process)
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
  def request(module, request, config, before_process, after_process) do
    hn_options = build_hackney_options(module, request.options)

    Logger.debug(["HTTP request started - ",
                  "module ", inspect(module), " - ",
                  "method ", inspect(request.method), ?\s,
                  request.url])
    Logger.debug(["HTTP request body: ", inspect(request.body)])
    start = :os.system_time(:milli_seconds)

    result = case do_request(request, hn_options) do
      {:ok, status_code, headers} ->
        Response.new(request, status_code, headers, "", config, before_process, after_process)
      {:ok, status_code, headers, client} ->
        case :hackney.body(client) do
          {:ok, body} ->
            Response.new(request, status_code, headers, body, config, before_process, after_process)
          {:error, reason} ->
            ConnError.new(reason, nil, config)
        end
      {:ok, id} -> AsyncResponse.new(id, config)
      {:error, reason} -> ConnError.new(reason, nil, config)
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
end

