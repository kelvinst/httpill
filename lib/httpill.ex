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

  ## Usage

  The `HTTPill` module can be used to make HTTP requests like this:

      iex> HTTPill.get!("https://api.github.com")
      %HTTPill.Response{status_code: 200,
                        headers: [{"content-type", "application/json"}],
                        body: "{...}"}

  If you want to create your own `HTTPill` extension, give `HTTPill.Base` a
  check. This module is nothing more than an empty module with only
  `use HTTPill.Base`, so you will find more documentation about how to make
  requests there.
  """

  use HTTPill.Base
end

