defmodule HTTPill.Request do
  defstruct [:body, :method, :url, :started_at, adapter_options: [], headers: []]
  @type t :: %__MODULE__{
    adapter_options: list,
    body: term,
    headers: list,
    method: atom,
    started_at: integer,
    url: binary
  }
end

defmodule HTTPill.Response do
  defstruct [:body, :received_at, :request_url, :status_code, headers: []]
  @type t :: %__MODULE__{
    body: term,
    headers: list,
    received_at: integer,
    request_url: binary,
    status_code: integer
  }
end

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

