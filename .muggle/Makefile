include .muggle/help.make
.DELETE_ON_ERROR:

.PHONY: all help lint

.DEFAULT_GOAL := help

## Run all targets
all: render

## Lint code base
lint:
	@echo "Linting ..."
	docker compose up super-linter
	@echo "... linting done."
