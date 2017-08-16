defmodule HTTPill.ConnError do
  @moduledoc """
  Represents an error when trying to connect
  """

  defexception reason: nil, id: nil

  alias HTTPill.Config
  alias HTTPill.ConnError

  @type t :: %ConnError{id: reference | nil, reason: any}

  @doc """
  Returns a brand new `ConnError` response.
  """
  @spec new(any, reference | nil, Config.t) :: any
  def new(reason, id, config) do
    error = %ConnError{reason: reason, id: id}
    case config.response_handling_method do
      :no_tuple -> error
      _ -> {:error, error}
    end
  end

  @doc """
  Returns the message for the given `error`
  """
  @spec message(t) :: binary
  def message(error)
  def message(%ConnError{reason: reason, id: nil}) do
    inspect(reason)
  end
  def message(%ConnError{reason: reason, id: id}) do
    "[Reference: #{id}] - #{inspect reason}"
  end
end

