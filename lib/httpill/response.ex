defmodule HTTPill.Response do
  @moduledoc """
  Represents an HTTP response and carries all the information returned from a
  `HTTPill.Request`, all along with the `request` itself.

  To get a new response with correctly handled data, please give a check on the
  `new/5` function.
  """

  defstruct [:body, :request, :status_code, headers: []]

  alias HTTPill.Config
  alias HTTPill.HeaderList
  alias HTTPill.Request
  alias HTTPill.Response

  @type t :: %Response{
    body: term,
    headers: HTTPill.HeaderList.t,
    request: HTTPill.Request.t,
    status_code: integer
  }
  @type result ::
    {:ok, Response.t | AsyncResponse.t} |
    {:status_error, Response.t}

  @doc """
  Creates a brand new response, correctly handling body parsing and other
  things, making it ready to be worked on.
  """
  @spec new(Request.t, integer, HeaderList.t, binary, Config.t, function, function) ::
    Response.result
  def new(request, status_code, headers, body, config, before_process, after_process) do
    response =
      %Response{
        status_code: status_code,
        headers: headers,
        body: body,
        request: request
      }
      |> before_process.()
      |> decode_response_body(HeaderList.get(request.headers, "Accepts"))
      |> after_process.()

    case config.response_handling_method do
      :no_tuple -> response
      :conn_error -> {:ok, response}
      :status_error ->
        if response.status_code >= 400 do
          {:status_error, response}
        else
          {:ok, response}
        end
    end
  end

  defp decode_response_body(resp, nil) do
    resp
  end
  defp decode_response_body(%Response{body: body} = resp, accepts) do
    if String.contains?(accepts, "json") do
      case Poison.decode(body) do
        {:ok, map} -> %{resp | body: map}
        _ -> resp
      end
    else
      body
    end
  end
end


