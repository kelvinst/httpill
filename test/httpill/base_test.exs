defmodule HTTPillBaseTest do
  use ExUnit.Case
  import :meck

  defmodule Example do
    use HTTPill.Base
    def after_process_request(request) do
      %{request |
        body: {:req_body, request.body},
        options: Keyword.put(request.options, :timeout, 10)}
    end
    def after_process_response(response) do
      %{response |
        body: {:resp_body, response.body},
        status_code: {:code, response.status_code}}
    end
  end

  defmodule ExampleDefp do
    use HTTPill.Base
    defp after_process_request(request) do
      %{request |
        body: {:req_body, request.body},
        options: Keyword.put(request.options, :timeout, 10)}
    end
    defp after_process_response(response) do
      %{response |
        body: {:resp_body, response.body},
        status_code: {:code, response.status_code}}
    end
  end

  defmodule ExampleParamsOptions do
    use HTTPill.Base
    def before_process_request(request) do
      %{request |
        params: Map.merge(request.params, %{key: "fizz"})}
    end
  end

  defmodule ConfigPill do
    use HTTPill.Base

    Application.put_env(:httpill,
                        __MODULE__,
                        response_handling_method: :status_error,
                        base_url: "config",
                        request_headers: [{"Header", "env"}])
  end

  defmodule OptPill do
    use HTTPill.Base,
      response_handling_method: :no_tuple,
      base_url: "opt",
      request_headers: [{"Header", "opt"}]
  end

  setup do
    new :hackney
    on_exit fn -> unload() end
    :ok
  end

  test "request body using Example" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], {:req_body, "body"}, [{:connect_timeout, 10}]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: {:code, 200},
      headers: [],
      body: {:resp_body, "response"}
    } = Example.post!("localhost", body: "body")

    assert validate :hackney
  end

  test "request body using ExampleDefp" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], {:req_body, "body"}, [{:connect_timeout, 10}]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: {:code, 200},
      headers: [],
      body: {:resp_body, "response"}
    } = ExampleDefp.post!("localhost", body: "body")

    assert validate :hackney
  end

  test "request body using params example" do
    expect(:hackney, :request, [{[:get, "http://localhost?foo=bar&key=fizz", [], "", []],
                                {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = ExampleParamsOptions.get!("localhost", params: %{foo: "bar"})

    assert validate :hackney
  end

  test "request raises error tuple" do
    reason = {:closed, "Something happened"}
    expect(:hackney, :request, 5, {:error, reason})

    assert_raise HTTPill.ConnError, "{:closed, \"Something happened\"}", fn ->
      HTTPill.get!("http://localhost")
    end

    assert HTTPill.get("http://localhost") == {:error, %HTTPill.ConnError{reason: reason}}

    assert validate :hackney
  end

  test "passing connect_timeout option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [connect_timeout: 12345]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response",
    } = HTTPill.post!("localhost", body: "body", timeout: 12345)

    assert validate :hackney
  end

  test "passing recv_timeout option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [recv_timeout: 12345]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost", body: "body", recv_timeout: 12345)

    assert validate :hackney
  end

  test "passing proxy option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy: "proxy"]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost", body: "body", proxy: "proxy")

    assert validate :hackney
  end

  test "passing proxy option with proxy_auth" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy_auth: {"username", "password"}, proxy: "proxy"]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost",
                      body: "body",
                      proxy: "proxy",
                      proxy_auth: {"username", "password"})

    assert validate :hackney
  end

  test "passing ssl option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [ssl_options: [certfile: "certs/client.crt"]]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response",
    } = HTTPill.post!("localhost",
                      body: "body",
                      ssl: [certfile: "certs/client.crt"])

    assert validate :hackney
  end

  test "passing follow_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [follow_redirect: true]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost", body: "body", follow_redirect: true)

    assert validate :hackney
  end

  test "passing max_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [max_redirect: 2]],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost", body: "body", max_redirect: 2)

    assert validate :hackney
  end

  test "sending a map as the body" do
    expect(:hackney, :request, [{[:post, "http://localhost", [{"Content-Type", "application/json; charset=UTF-8"}], "{\"a\":1}", []],
                                 {:ok, 200, [], :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert %HTTPill.Response{
      status_code: 200,
      headers: [],
      body: "response"
    } = HTTPill.post!("localhost", body: %{a: 1})

    assert validate :hackney

  end

  test "receiveing a map for Accepts application/json" do
    expect(:hackney, :request, [{
             [:post, "http://localhost", [{"Content-Type", "application/json; charset=UTF-8"}, {"Accepts", "application/json; charset=UTF-8"}], "{\"a\":1}", []],
             {:ok, 200, [], :client}
           }])
    expect(:hackney, :body, 1, {:ok, "{\"a\":1}"})

    assert %HTTPill.Response{
      status_code: 200,
      body: %{"a" => 1}
    } = HTTPill.post!("localhost",
                      headers: %{
                        "Accepts" => "application/json; charset=UTF-8"
                      },
                      body: %{a: 1})

    assert validate :hackney
  end

  test "request with config as env" do
    expect(:hackney, :request, [{
             [:get, "http://config/this", [{"Header", "env"}], "", []],
             {:ok, 400, [], :client}
           }])
    expect(:hackney, :body, 1, {:ok, "body"})

    assert {:status_error, %HTTPill.Response{
      status_code: 400,
      body: "body",
      request: %{url: "http://config/this"}
    }} = ConfigPill.get("this")
  end

  test "request with config as option" do
    expect(:hackney, :request, [{
             [:get, "http://opt/this", [{"Header", "opt"}], "", []],
             {:ok, 200, [], :client}
           }])
    expect(:hackney, :body, 1, {:ok, "body"})

    assert %HTTPill.Response{
      status_code: 200,
      body: "body",
      request: %{url: "http://opt/this"}
    } = OptPill.get("this")
  end
end
