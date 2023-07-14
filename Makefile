PLT_DIR := $(shell elixir -e 'IO.puts Mix.Utils.mix_home')

# List any targets that are not an actual file here to ensure they are always run
.PHONY: all start-ticket clean mrproper deps deps_unlock test dialyzer update outdated setup

# Default: make sure we're green.
all: setup deps test

# If you start on a ticket, you really want to make sure we're green. However,
# `make mrproper` is a bit too much for the default (`all`) target, so make
# invocation explicit.
start-ticket: mrproper all

recompile:
	mix compile --force --warnings-as-errors

clean:
	mrproper

mrproper:
	git clean -dfx

deps:
	mix deps.get

deps_unlock:
	mix deps.unlock --unused

test: deps
	mix test --color

checks:
	make recompile
	mix format --check-formatted

dialyzer: deps
	mix dialyzer

update:
	mix deps.update --all

outdated:
	mix hex.outdated

# Shows all Hex dependencies that have been marked as retired. Retired packages
# are no longer recommended to be used by their maintainers.
audit:
	mix hex.audit

setup: 
	asdf install
	mix local.hex --force --if-missing
	mix local.rebar --force
	mix deps.get

format.check:
	mix format --check-formatted

format:
	mix format

coverage:
	MIX_ENV=test SHORT_ENVIRONMENT_TAG=test ENVIRONMENT_TAG=test mix do deps.get, coveralls.html --umbrella
