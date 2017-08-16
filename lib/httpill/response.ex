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
    headers: HeaderList.t,
    request: Request.t,
    status_code: integer
  }

  @doc """
  Creates a brand new response, correctly handling body parsing and other
  things, making it ready to be worked on.
  """
  @spec new(list, Config.t, function, function) ::
    {:ok, Response.t | AsyncResponse.t} |
    {:status_error, Response.t}
  def new(args, config, before_process, after_process) do
    response =
      Response
      |> struct(args)
      |> before_process.()
      |> decode_response_body()
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

  defp decode_response_body(%Response{request: request} = resp) do
    decode_response_body(resp, HeaderList.get(request.headers, "Accepts"))
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


