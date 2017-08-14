defmodule HTTPill do
  @moduledoc """
  HTTP requests for sick people!

  The cure for some poison or potion you might be drinking in the web.

  Puns aside, [HTTPoison](https://github.com/edgurgel/httpoison) and
  [HTTPotion](https://github.com/myfreeweb/httpotion) are both great tools,
  but we wanted more!

  Here's what we wanted:

  - Debug logging
  - Return a `Stream` for async chunked responses handling
  - Auto discovering `Content-Type` based on the given request body
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
  """
end
