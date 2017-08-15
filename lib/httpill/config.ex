defmodule HTTPill.Config do
  @moduledoc """
  Here is all you can find about configuring HTTPill!

  This module is responsible for loading and handling the configuration for
  any `HTTPill.Base` client, either the default `HTTPill` module or any other
  client you've created!

  ## Config options

  - `adapter` - the adapter to use, `:hackney` by default, the available
  options are `:hackney` and `:ibrowse`
  - `base_url` - the url to prepend to all requests, `""` by default
  - `request_headers` - the headers to add to all requests, `[]` by default
  - `response_handling_method` - the way to handle responses, `:conn_error` by
  default, the current options are:
    - `:conn_error` - the requests return `{:error, reason}` for connection
    errors and `{:ok, resp}` otherwise
    - `:status_error` - the requests return `{:error, reason}` for conn errors,
    `{:status_error, resp}` for successful requests with status codes >= 400 and
    `{:ok, resp}` otherwise
    - `:no_tuple` - the requests return a `%HTTPill.ConnError{}` for conn
    errors and a `%HTTPill.Response{}` otherwise
  """

  defstruct [
    :base_url,
    adapter: :hackney,
    request_headers: [],
    response_handling_method: :conn_error
  ]
  @type t :: %__MODULE__{
    adapter: atom,
    base_url: binary,
    request_headers: HTTPill.HeaderList.t,
    response_handling_method: atom
  }
end

