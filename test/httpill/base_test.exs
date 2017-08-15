defmodule HTTPillBaseTest do
  use ExUnit.Case
  import :meck

  defmodule Example do
    use HTTPill.Base
    def process_url(url), do: "http://" <> url
    def process_request_body(body), do: {:req_body, body}
    def process_request_headers(headers), do: {:req_headers, headers}
    def process_request_options(options), do: Keyword.put(options, :timeout, 10)
    def process_response_body(body), do: {:resp_body, body}
    def process_headers(headers), do: {:headers, headers}
    def process_status_code(code), do: {:code, code}
  end

  defmodule ExampleDefp do
    use HTTPill.Base
    defp process_url(url), do: "http://" <> url
    defp process_request_body(body), do: {:req_body, body}
    defp process_request_headers(headers), do: {:req_headers, headers}
    defp process_request_options(options), do: Keyword.put(options, :timeout, 10)
    defp process_response_body(body), do: {:resp_body, body}
    defp process_headers(headers), do: {:headers, headers}
    defp process_status_code(code), do: {:code, code}
  end

  defmodule ExampleParamsOptions do
    use HTTPill.Base
    def process_url(url), do: "http://" <> url
    def process_request_params(params), do: Map.merge(params, %{key: "fizz"})
  end

  setup do
    new :hackney
    on_exit fn -> unload() end
    :ok
  end

  test "request body using Example" do
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [{:connect_timeout, 10}]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert Example.post!("localhost", body: "body") ==
    %HTTPill.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"},
                         request_url: "http://localhost" }

    assert validate :hackney
  end

  test "request body using ExampleDefp" do
    expect(:hackney, :request, [{[:post, "http://localhost", {:req_headers, []}, {:req_body, "body"}, [{:connect_timeout, 10}]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert ExampleDefp.post!("localhost", body: "body") ==
    %HTTPill.Response{ status_code: {:code, 200},
                         headers: {:headers, "headers"},
                         body: {:resp_body, "response"},
                         request_url: "http://localhost" }

    assert validate :hackney
  end

  test "request body using params example" do
    expect(:hackney, :request, [{[:get, "http://localhost?foo=bar&key=fizz", [], "", []], {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert ExampleParamsOptions.get!("localhost", params: %{foo: "bar"}) ==
      %HTTPill.Response{status_code: 200,
                        headers: "headers",
                        body: "response",
                        request_url: "http://localhost?foo=bar&key=fizz" }

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
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         timeout: 12345) ==
      %HTTPill.Response{status_code: 200,
                        headers: "headers",
                        body: "response",
                        request_url: "http://localhost" }

    assert validate :hackney
  end

  test "passing recv_timeout option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [recv_timeout: 12345]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         recv_timeout: 12345) ==
      %HTTPill.Response{status_code: 200,
                        headers: "headers",
                        body: "response",
                        request_url: "http://localhost" }

    assert validate :hackney
  end

  test "passing proxy option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy: "proxy"]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         proxy: "proxy") ==
      %HTTPill.Response{status_code: 200,
        headers: "headers",
        body: "response",
        request_url: "http://localhost"}

    assert validate :hackney
  end

  test "passing proxy option with proxy_auth" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [proxy_auth: {"username", "password"}, proxy: "proxy"]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         proxy: "proxy",
                         proxy_auth: {"username", "password"}) ==
      %HTTPill.Response{status_code: 200,
                        headers: "headers",
                        body: "response",
                        request_url: "http://localhost"}

    assert validate :hackney
  end

  test "passing ssl option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [ssl_options: [certfile: "certs/client.crt"]]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         ssl: [certfile: "certs/client.crt"]) ==
    %HTTPill.Response{ status_code: 200,
                         headers: "headers",
                         body: "response",
                         request_url: "http://localhost" }

    assert validate :hackney
  end

  test "passing follow_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [follow_redirect: true]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         follow_redirect: true) ==
    %HTTPill.Response{status_code: 200,
                      headers: "headers",
                      body: "response",
                      request_url: "http://localhost" }

    assert validate :hackney
  end

  test "passing max_redirect option" do
    expect(:hackney, :request, [{[:post, "http://localhost", [], "body", [max_redirect: 2]],
                                 {:ok, 200, "headers", :client}}])
    expect(:hackney, :body, 1, {:ok, "response"})

    assert HTTPill.post!("localhost",
                         body: "body",
                         max_redirect: 2) ==
      %HTTPill.Response{status_code: 200,
                        headers: "headers",
                        body: "response",
                        request_url: "http://localhost" }

    assert validate :hackney
  end
end
