defmodule HTTPill.Adapter do
  @moduledoc """
  This module defines the behaviour which all HTTPill adapters must follow
  """

  alias HTTPill.Adapter
  alias HTTPill.Config
  alias HTTPill.Request

  @type after_process_async_response :: function
  @type before_process_response :: function
  @type after_process_response :: function
  @type adapter_response :: any

  defmacro __using__(_) do
    quote do
      @behaviour Adapter

      @doc """
      Makes the given `request` through this adapter
      """
      @spec request(Request.t,
                    Config.t,
                    Adapter.before_process_response,
                    Adapter.after_process_response) :: HTTPill.response
      def request(request, config, before_process, after_process) do
        request
        |> issue_request(before_process, after_process)
        |> handle_response(request, config, before_process, after_process)
      end
    end
  end

  @doc """
  Issues the given `request` through the implemented adapter
  """
  @callback issue_request(Request.t,
                          before_process_response,
                          after_process_response) :: adapter_response

  @doc """
  Handles the `adapter_response` which is teh result of from `issue_request/2`

  Must call `before_process_response` and `after_process_response` callbacks
  """
  @callback handle_response(adapter_response,
                            Request.t,
                            Config.t,
                            before_process_response,
                            after_process_response) :: HTTPill.response
end
