.PHONY: lint format generate breaking verify-go check

lint:
	buf lint

format:
	buf format -w

generate:
	rm -rf gen/go
	buf generate

breaking:
	buf breaking --against '.git#branch=main'

verify-go:
	test -d gen/go

check: lint generate breaking verify-go
