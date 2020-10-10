SHELL:=/bin/bash
CWD?=.
COMMIT?=$(shell git rev-parse --short HEAD)
DOCKER=docker run --rm -it -v $(PWD):/usr/app -w /usr/app

.PHONY: test

help:
	@echo "	test						run all tests locally"

test:
	./tests/test_grep_ticket_number.sh
	$(DOCKER) ubuntu:latest /bin/bash ./tests/test_grep_ticket_number.sh
