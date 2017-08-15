defmodule HTTPill.AsyncResponse do
  defstruct id: nil
  @type t :: %__MODULE__{id: reference}
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

