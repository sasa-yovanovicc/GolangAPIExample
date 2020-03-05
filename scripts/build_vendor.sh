#!/bin/bash

set -x

go mod init
go get -u ./...
go mod vendor
