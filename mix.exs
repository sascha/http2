defmodule HTTP2.Mixfile do
  use Mix.Project

  def project do
    [app: :http2,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: "http2 is an HTTP/2 client for Elixir",
     package: [
       maintainers: ["Sascha Schwabbauer"],
       links: %{"GitHub" => "https://github.com/sascha/http2"}
     ]]
  end

  def application do
    [mod: {HTTP2.Application, []},
    applications: [:ranch, :ssl, :logger],
    registered: [HTTP2.Supervisor]]
  end

  defp deps do
    [{:ranch, github: "ninenines/ranch"},
    {:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
end
