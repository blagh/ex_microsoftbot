defmodule ExMicrosoftBot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ex_microsoftbot,
      version: "3.0.0",
      elixir: "~> 1.8",
      description: description(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "test.all": :test
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ]
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev],
    do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  def description do
    "This library provides Elixir API wrapper for the Microsoft Bot Framework."
  end

  defp package do
    [
      licenses: ["MIT License"],
      maintainers: ["Zohaib Rauf", "Ben Hayden"],
      links: %{
        "GitHub" => "https://github.com/zabirauf/ex_microsoftbot",
        "Docs" => "https://hexdocs.pm/ex_microsoftbot/"
      }
    ]
  end

  def application do
    [
      mod: {ExMicrosoftBot, []},
      env: [
        endpoint: "https://api.botframework.com",
        openid_valid_keys_url:
          "https://login.botframework.com/v1/.well-known/openidconfiguration",
        issuer_claim: "https://api.botframework.com",
        audience_claim: Application.get_env(:ex_microsoftbot, :app_id),
        disable_token_validation: false
      ],
      registered: [ExMicrosoftBot.TokenManager, ExMicrosoftBot.SigningKeysManager],
      applications: applications(Mix.env())
    ]
  end

  defp applications(env) when env in [:dev, :prod] do
    [:logger, :jose, :tzdata, :timex, :poison, :stats_owl, :httpoison]
  end

  defp applications(:test) do
    applications(:dev) ++ [:bypass, :mimic, :excoveralls]
  end

  defp deps do
    [
      {:stats_owl, git: "git@github.com:PagerDuty/stats-owl.git", tag: "3.1.0"},
      {:excoveralls, "~> 0.16.1", only: :test},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_unit_notifier, "~> 1.2", only: [:dev, :test], runtime: false},
      {:httpoison, "~> 2.0"},
      {:poison, "~> 4.0"},
      {:jose, "~> 1.7"},
      {:timex, "~> 3.0"},
      {:jason, "~> 1.2"},
      {:tzdata, "~> 1.0"},
      {:inch_ex, "~> 2.0.0", only: :docs},
      {:dialyxir, "~> 0.3", only: [:dev]},
      {:ex_doc, "~> 0.19", only: [:dev]},
      {:bypass, "~> 2.1", only: :test},
      # Required by bypass, incompatible with OTP 22 since 2.8.0:
      {:cowboy, "~> 2.10.0", only: :test},
      {:mimic, "~> 1.7", only: :test}
    ]
  end
end
