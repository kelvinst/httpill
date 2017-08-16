defmodule HTTPill.Adapter.Hackney do
  @moduledoc """
  The hackney adapter for HTTPill
  """

  use HTTPill.Adapter

  alias HTTPill.Adapter
  alias HTTPill.AsyncChunk
  alias HTTPill.AsyncEnd
  alias HTTPill.AsyncHeaders
  alias HTTPill.AsyncRedirect
  alias HTTPill.AsyncResponse
  alias HTTPill.AsyncStatus
  alias HTTPill.ConnError
  alias HTTPill.Request
  alias HTTPill.Response

  @impl Adapter
  def issue_request(request, before_process, after_process) do
    request.options
    |> build_options(before_process, after_process)
    |> do_request(request)
  end

  defp build_options(options, before_process, after_process) do
    timeout = Keyword.get options, :timeout
    recv_timeout = Keyword.get options, :recv_timeout
    stream_to = Keyword.get options, :stream_to
    async = Keyword.get options, :async
    proxy = Keyword.get options, :proxy
    proxy_auth = Keyword.get options, :proxy_auth
    ssl = Keyword.get options, :ssl
    follow_redirect = Keyword.get options, :follow_redirect
    max_redirect = Keyword.get options, :max_redirect

    options = Keyword.get options, :hackney, []

    options = if timeout, do: [{:connect_timeout, timeout} | options], else: options
    options = if recv_timeout, do: [{:recv_timeout, recv_timeout} | options], else: options
    options = if proxy, do: [{:proxy, proxy} | options], else: options
    options = if proxy_auth, do: [{:proxy_auth, proxy_auth} | options], else: options
    options = if ssl, do: [{:ssl_options, ssl} | options], else: options
    options = if follow_redirect, do: [{:follow_redirect, follow_redirect} | options], else: options
    options = if max_redirect, do: [{:max_redirect, max_redirect} | options], else: options

    options =
      if stream_to do
        async_option = case async do
          nil   -> :async
          :once -> {:async, :once}
        end
        [async_option,
         {
           :stream_to,
           spawn_link(__MODULE__,
                      :handle_async_response,
                      [stream_to, before_process, after_process])
         } |
         options]
      else
        options
      end

    options
  end

  defp do_request(options, %Request{body: {:stream, enumerable}} = request) do
    with {:ok, ref} <- :hackney.request(request.method,
                                        request.url,
                                        request.headers,
                                        :stream,
                                        options) do
      failures = Stream.transform(enumerable, :ok, fn
        _, :error -> {:halt, :error}
        bin, :ok  -> {[], :hackney.send_body(ref, bin)}
        _, error  -> {[error], :error}
      end)
      |> Enum.into([])

      case failures do
        [] ->
          :hackney.start_response(ref)
        [failure] ->
          failure
      end
    end
  end
  defp do_request(options, request) do
    :hackney.request(request.method,
                     request.url,
                     request.headers,
                     request.body,
                     options)
  end

  @impl Adapter
  def handle_response({:ok, status_code, headers}, request, config, before_process, after_process) do
    Response.new([request: request,
                  status_code: status_code,
                  headers: headers,
                  body: ""],
                 config,
                 before_process,
                 after_process)
  end
  def handle_response({:ok, status_code, headers, client}, request, config, before_process, after_process) do
    case :hackney.body(client) do
      {:ok, body} ->
        Response.new([request: request,
                      status_code: status_code,
                      headers: headers,
                      body: body],
                     config,
                     before_process,
                     after_process)
      {:error, reason} ->
        ConnError.new(reason, nil, config)
    end
  end
  def handle_response({:ok, id}, _, config, _, _) do
    AsyncResponse.new(id, config)
  end
  def handle_response({:error, reason}, _, config, _, _) do
    ConnError.new(reason, nil, config)
  end

  defp handle_async_response(target, before_process, after_process) do
    receive do
      {:hackney_response, id, {:status, code, _reason}} ->
        send(target,
             process_response(%AsyncStatus{id: id, code: code},
                              before_process,
                              after_process))
        handle_async_response(target, before_process, after_process)
      {:hackney_response, id, {:headers, headers}} ->
        send(target,
             process_response(%AsyncHeaders{id: id, headers: headers},
                              before_process,
                              after_process))
        handle_async_response(target, before_process, after_process)
      {:hackney_response, id, :done} ->
        send(target,
             process_response(%AsyncEnd{id: id},
                              before_process,
                              after_process))
      {:hackney_response, id, {:error, reason}} ->
        send target, %ConnError{id: id, reason: reason}
      {:hackney_response, id, {redirect, to, headers}}
      when redirect in [:redirect, :see_other] ->
        send(target,
             process_response(%AsyncRedirect{id: id, to: to, headers: headers},
                              before_process,
                              after_process))
      {:hackney_response, id, chunk} ->
        send(target,
             process_response(%AsyncChunk{id: id, chunk: chunk},
                              before_process,
                              after_process))
        handle_async_response(target, before_process, after_process)
    end
  end

  defp process_response(response, before_process, after_process) do
    response
    |> before_process.()
    |> after_process.()
  end
end

