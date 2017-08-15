defmodule HTTPill.HeaderList do
  @moduledoc """
  A `HTTPill.HeaderList` is intented to represent the list of headers for HTTP
  requests and responses.

  It can be represented in the form of a map or a key-value list (similar to
  keyword lists, but with strings as keys), but you it's recomended to use a
  key-value list, since it's allowed to have multiple value for a same key.
  """

  @type t :: [{binary, binary}] | %{binary => binary}

  @doc """
  Gets the given `header` on the `list`.

  Returns `default_value` if no header found.
  """
  @spec get(t, binary, term) :: term
  def get(list, header, default_value \\ nil) when is_list(list) or is_map(list) do
    Enum.find_value list, default_value, fn({key, value}) ->
      if key == header, do: value
    end
  end

  @doc """
  Puts the given `value` for the `key` on the `list`.
  """
  @spec put(t, binary, binary) :: t
  def put(list, key, value) when is_list(list) do
    [{key, value} | list]
  end
  def put(list, key, value) when is_map(list) do
    Map.put(list, key, value)
  end

  @doc """
  Normalizes the `list` to the prefered way, a key-value list.
  """
  @spec normalize(t) :: t
  def normalize(list) when is_map(list) do
    Enum.into list, []
  end
  def normalize(list) when is_list(list) do
    list
  end
end
