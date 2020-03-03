#!/bin/bash

set -x

currentPath=`pwd`

rm -rf $GOPATH/src/github.com/go-swagger

go get github.com/go-swagger/go-swagger
go get github.com/go-swagger/go-swagger/cmd/swagger

#cd $currentPath
