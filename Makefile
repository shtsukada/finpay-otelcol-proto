.PHONY: lint format breaking generate

lint:
	buf lint

format:
	buf format -w

breaking:
	buf breaking --against '.git#branch=main'

generate:
	rm -rf gen/go
	buf generate