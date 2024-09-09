Application.ensure_all_started(:mimic)
Code.put_compiler_option(:warnings_as_errors, true)
ExUnit.start(timeout: 2000)

[
  Application,
  JOSE.JWT,
  StatsOwl
]
|> Enum.each(&Mimic.copy/1)
