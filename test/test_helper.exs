Application.ensure_all_started(:mimic)

[
  Application,
  JOSE.JWT,
  StatsOwl
]
|> Enum.each(&Mimic.copy/1)

ExUnit.start()
