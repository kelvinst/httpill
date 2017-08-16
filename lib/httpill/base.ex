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

  ## Configuring

  You can configure your `HTTPill.Base` modules passing the opts when you're
  using it, like this:

      defmodule Google do
        use HTTPill.Base, base_url: "https://api.google.com"
      end

  Or even on your whole env, by setting this on your config files:

      config :httpill, Google, base_url: "https://api.google.com"

  ## Overriding functions

  `HTTPill.Base` defines a behaviour for the function callbacks that you can
  implement. Just give a check on the callback list.

  All of this functions are optionally overridable on your extensions.
  """

  alias HTTPill.AsyncResponse
  alias HTTPill.Base
  alias HTTPill.Config
  alias HTTPill.ConnError
  alias HTTPill.Request
  alias HTTPill.Response
  alias HTTPill.StatusError

  defmacro __using__(opts) do
    quote do
      require Logger

      @behaviour Base

      @doc """
      Returns the configuration for this module.
      """
      @spec config() :: Config.t
      def config, do: Base.config(__MODULE__, unquote(opts))

      @doc """
      Starts HTTPill and its dependencies.
      """
      def start, do: :application.ensure_all_started(:httpill)

      @impl Base
      def before_process_request(request), do: request

      @impl Base
      def after_process_request(request), do: request

      @impl Base
      def before_process_response(response), do: response

      @impl Base
      def after_process_response(response), do: response

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
      @spec request(atom, binary, Keyword.t) :: HTTPill.response
      def request(method, url, options \\ []) do
        cfg = config()
        request = Request.new(method,
                              url,
                              options,
                              cfg,
                              &before_process_request/1,
                              &after_process_request/1)

        Logger.debug(["HTTP request started - ",
                      "module=", inspect(__MODULE__), ?\s,
                      "adapter=", inspect(cfg.adapter), ?\s,
                      "method=", inspect(request.method), ?\s,
                      "url=", inspect(request.url)])
        start = :os.system_time(:milli_seconds)

        result = cfg.adapter.request(request,
                                     cfg,
                                     &before_process_response/1,
                                     &after_process_response/1)

        duration = :os.system_time(:milli_seconds) - start
        Logger.debug(["HTTP request ended - ",
                      "module=", inspect(__MODULE__), ?\s,
                      "adapter=", inspect(cfg.adapter), ?\s,
                      "method=", inspect(request.method), ?\s,
                      "url=", request.url, ?\s,
                      "time=", inspect(duration), "ms"])

        result
      end

      @doc """
      Issues an HTTP request with the given method to the given url, raising an
      exception in case of failure.

      `request!/3` works exactly like `request/3` but it returns just the
      response in case of a successful request, raising an exception in case the
      request fails.
      """
      @spec request!(atom, binary, Keyword.t) :: Response.t | AsyncResponse.t
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

      See `request/3` for more detailed information.
      """
      @spec get(binary, Keyword.t) :: HTTPill.response
      def get(url, options \\ []), do: request(:get, url, options)

      @doc """
      Issues a GET request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec get!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def get!(url, options \\ []), do: request!(:get, url, options)

      @doc """
      Issues a PUT request to the given url.

      See `request/3` for more detailed information.
      """
      @spec put(binary, Keyword.t) :: HTTPill.response
      def put(url, options \\ []), do: request(:put, url, options)

      @doc """
      Issues a PUT request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec put!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def put!(url, options \\ []), do: request!(:put, url, options)

      @doc """
      Issues a HEAD request to the given url.

      See `request/3` for more detailed information.
      """
      @spec head(binary, Keyword.t) :: HTTPill.response
      def head(url, options \\ []), do: request(:head, url, options)

      @doc """
      Issues a HEAD request to the given url, raising an exception in case of
      failure.

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
      @spec post(binary, Keyword.t) :: HTTPill.response
      def post(url, options \\ []), do: request(:post, url, options)

      @doc """
      Issues a POST request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec post!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def post!(url, options \\ []), do: request!(:post, url, options)

      @doc """
      Issues a PATCH request to the given url.

      See `request/3` for more detailed information.
      """
      @spec patch(binary, Keyword.t) :: HTTPill.response
      def patch(url, options \\ []), do: request(:patch, url, options)

      @doc """
      Issues a PATCH request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec patch!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def patch!(url, options \\ []), do: request!(:patch, url, options)

      @doc """
      Issues a DELETE request to the given url.

      See `request/3` for more detailed information.
      """
      @spec delete(binary, Keyword.t) :: HTTPill.response
      def delete(url, options \\ []), do: request(:delete, url, options)

      @doc """
      Issues a DELETE request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec delete!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def delete!(url, options \\ []), do: request!(:delete, url, options)

      @doc """
      Issues an OPTIONS request to the given url.

      See `request/3` for more detailed information.
      """
      @spec options(binary, Keyword.t) :: HTTPill.response
      def options(url, options \\ []), do: request(:options, url, options)

      @doc """
      Issues a OPTIONS request to the given url, raising an exception in case of
      failure.

      See `request!/3` for more detailed information.
      """
      @spec options!(binary, Keyword.t) :: Response.t | AsyncResponse.t
      def options!(url, options \\ []), do: request!(:options, url, options)

      @doc """
      Requests the next message to be streamed for a given
      `HTTPill.AsyncResponse`.
      """
      @spec stream_next(AsyncResponse.t) ::
        {:ok, AsyncResponse.t} |
        {:error, ConnError.t}
      def stream_next(resp = %AsyncResponse{ id: id }) do
        case :hackney.stream_next(id) do
          :ok -> {:ok, resp}
          err -> {:error, %ConnError{reason: "stream_next/1 failed", id: id}}
        end
      end

      defoverridable Module.definitions_in(__MODULE__)
    end
  end

  @doc """
  Returns the configuration for the given `module`.

  This function merges the env configuration on top of the given
  `default_config`, which is empty by default.
  """
  def config(module, default_config \\ []) do
    struct(Config,
           Keyword.merge(default_config,
                         Application.get_env(:httpill, module, [])))
  end

  @doc """
  Called before processing any request
  """
  @callback before_process_request(Request.t) :: Request.t

  @doc """
  Called after processing any request
  """
  @callback after_process_request(Request.t) :: Request.t

  @doc """
  Called before processing any response (async too)
  """
  @callback before_process_response(Response.t | AsyncResponse.any_t) ::
    Response.t | AsyncResponse.any_t

  @doc """
  Called after processing any response (async too)
  """
  @callback after_process_response(Response.t | AsyncResponse.any_t) ::
    Response.t | AsyncResponse.any_t

  @optional_callbacks [
    before_process_request: 1,
    after_process_request: 1,
    before_process_response: 1,
    after_process_response: 1
  ]
end

