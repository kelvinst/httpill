defmodule HTTPill.Response do
  defstruct status_code: nil, body: nil, headers: [], request_url: nil
  @type t :: %__MODULE__{status_code: integer, body: term, headers: list}
end

defmodule HTTPoison.AsyncResponse do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

defmodule HTTPoison.AsyncStatus do
  defstruct id: nil, code: nil
  @type t :: %__MODULE__{id: reference, code: integer}
end

defmodule HTTPoison.AsyncHeaders do
  defstruct id: nil, headers: []
  @type t :: %__MODULE__{id: reference, headers: list}
end

defmodule HTTPoison.AsyncChunk do
  defstruct id: nil, chunk: nil
  @type t :: %__MODULE__{id: reference, chunk: binary}
end

defmodule HTTPoison.AsyncRedirect do
  defstruct id: nil, to: nil, headers: []
  @type t :: %__MODULE__{id: reference, to: String.t, headers: list}
end

defmodule HTTPoison.AsyncEnd do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
end

