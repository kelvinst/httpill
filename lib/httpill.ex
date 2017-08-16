defmodule HTTPill do
  @moduledoc """
  HTTP requests for sick people!

  The cure for some poison or potion you might be drinking in the web.

  ## Why!?

  Puns aside, [HTTPoison](https://github.com/edgurgel/httpoison) and
  [HTTPotion](https://github.com/myfreeweb/httpotion) are both great tools, in
  the beginning this was nothing more than a merge of a lot of code from both,
  but we wanted more!

  Here's what we wanted:

  - Debug logging
  - Less callbacks to override, just one for requests and one for responses
  - Auto JSON encoding/decoding for the request/response body according to
  `Content-Type` and `Accepts`
  - Some slightly different response handling options, like returning
  `{:status_error, response}` for successful requests with status code >= 400,
  or not returning a tuple at all
  - Support for both `hackney` and `ibrowse`, or any other lib that comes to
  your mind in the future (and yes, you can switch between them anytime)
  - Replaceable default configurations, like `base_url` and `request_headers`
  for raw `HTTPill` calls. No overrides needed!
    - BONUS: also a standard way to set config options to your `HTTPill.Base`
    extensions

  ## Configuration

  You can configure this module behavior on your own config files like this:

      config :httpill, HTTPill, base_url: "api.github.com"

  For mor information about the config options you have, check the
  `HTTPill.Config` module docs.

  ## Usage

  The `HTTPill` module can be used to make HTTP requests like this:

      iex> HTTPill.get!("api.github.com")
      %HTTPill.Response{status_code: 200,
                        headers: [{"content-type", "application/json"}],
                        body: ""
                        request: %HTTPill.Request{...}}

  If you want to create your own `HTTPill` extension, give `HTTPill.Base` a
  check.
  """

  use HTTPill.Base

  alias HTTPill.AsyncResponse
  alias HTTPill.ConnError
  alias HTTPill.Response

  @type response ::
    {:ok, Response.t | AsyncResponse.t} |
    {:status_error, Response.t} |
    {:error, ConnError.t} |
    Response.t |
    AsyncResponse.t |
    ConnError.t
end

