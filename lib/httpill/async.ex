defmodule HTTPill.AsyncResponse do
  @moduledoc """
  Represents a response for an asyncronous HTTP request
  """

  alias HTTPill.AsyncResponse
  alias HTTPill.Config

  defstruct id: nil

  @type t :: %AsyncResponse{id: reference}

  @doc """
  Returns a brand new `AsyncResponse` correctly built for responding requests
  """
  @spec new(reference, Config.t) :: t
  def new(id, config) do
    struct = %HTTPill.AsyncResponse{id: id}
    case config.response_handling_method do
      :no_tuple -> struct
      _ -> {:ok, struct}
    end

  end
end

defmodule HTTPill.AsyncStatus do
  defstruct id: nil, code: nil
  @type t :: %__MODULE__{id: reference, code: integer}
end

defmodule HTTPill.AsyncHeaders do
  defstruct id: nil, headers: []
  @type t :: %__MODULE__{id: reference, headers: list}
end

defmodule HTTPill.AsyncChunk do
  defstruct id: nil, chunk: nil
  @type t :: %__MODULE__{id: reference, chunk: binary}
end

defmodule HTTPill.AsyncRedirect do
  defstruct id: nil, to: nil, headers: []
  @type t :: %__MODULE__{id: reference, to: String.t, headers: list}
end

defmodule HTTPill.AsyncEnd do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

