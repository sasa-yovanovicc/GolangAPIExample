#!/bin/bash

set -x

rm -rf vendor/
rm -f go.mod
rm -f go.sum

go mod init
go get -u ./...
go mod vendor
