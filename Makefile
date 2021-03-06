BASE_DIR=$(shell echo $$GOPATH)/src/github.com/jdkato/prose
BUILD_DIR=./builds
COMMIT= `git rev-parse --short HEAD 2>/dev/null`

VERSION_FILE=$(BASE_DIR)/VERSION
VERSION=$(shell cat $(VERSION_FILE))

LDFLAGS=-ldflags "-s -w -X main.Version=$(VERSION)"

.PHONY: clean test lint ci cross install bump model setup

all: build

build:
	go build ${LDFLAGS} -o bin/prose ./cmd/prose

build-win:
	go build ${LDFLAGS} -o bin/prose.exe ./cmd/prose

bench:
	go test -bench=. ./tokenize ./transform ./summarize

test-tokenize:
	go test -v ./tokenize

test-transform:
	go test -v ./transform

test-summarize:
	go test -v ./summarize

test-chunk:
	go test -v ./chunk

test: test-tokenize test-transform test-summarize test-chunk

ci: test lint

lint:
	gometalinter --vendor --disable-all \
		--enable=deadcode \
		--enable=ineffassign \
		--enable=gosimple \
		--enable=staticcheck \
		--enable=gofmt \
		--enable=goimports \
		--enable=misspell \
		--enable=errcheck \
		--enable=vet \
		--enable=vetshadow \
		--deadline=1m \
		./tokenize ./tag ./transform ./summarize ./chunk

setup:
	go get -u github.com/jdkato/syllables
	go get -u github.com/montanaflynn/stats
	go get -u gopkg.in/neurosnap/sentences.v1/english
	go get -u github.com/stretchr/testify/assert
	go get -u github.com/urfave/cli
	go get -u github.com/alecthomas/gometalinter
	go get -u github.com/jteeuwen/go-bindata/...
	go-bindata -ignore=\\.DS_Store -pkg="model" -o internal/model/model.go internal/model/
	gometalinter --install

bump:
	MAJOR=$(word 1, $(subst ., , $(CURRENT_VERSION)))
	MINOR=$(word 2, $(subst ., , $(CURRENT_VERSION)))
	PATCH=$(word 3, $(subst ., , $(CURRENT_VERSION)))
	VER ?= $(MAJOR).$(MINOR).$(shell echo $$(($(PATCH)+1)))

	echo $(VER) > $(VERSION_FILE)

model:
	go-bindata -ignore=\\.DS_Store -pkg="model" -o internal/model/model.go internal/model/
