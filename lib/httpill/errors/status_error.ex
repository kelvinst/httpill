defmodule HTTPill.StatusError do
  @moduledoc """
  Represents an error for not successful status codes
  """

  defexception response: nil

  alias HTTPill.Response
  alias HTTPill.StatusError

  @type t :: %StatusError{response: Response.t}

  @doc """
  Returns the message for the given `error`
  """
  @spec message(t) :: binary
  def message(error) do
    response = error.response
    request = response.request

    """
    The call to the #{request.method} request on #{request.url} returned the
    status code #{response.status_code}:

        #{inspect(response)}

    """
  end
end

