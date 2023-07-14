Application.ensure_all_started(:mimic)

[
  Application,
  StatsOwl
]
|> Enum.each(&Mimic.copy/1)

ExUnit.start()
