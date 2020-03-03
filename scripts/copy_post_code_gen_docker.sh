#!/bin/bash

[ ! -d "./restapi/custom" ] && mkdir -p "./restapi/custom"

if [ -f ./post_code_gen/custom/usersapi_func.go.bak.DOCKER ]; then
    cp ./post_code_gen/custom/usersapi_func.go.bak.DOCKER ./restapi/custom/usersapi_func.go
fi

if [ -f ./post_code_gen/custom/usersapi_func_test.go.bak ]; then
    cp ./post_code_gen/custom/usersapi_func_test.go.bak ./restapi/custom/usersapi_func_test.go
fi
if [ -f ./post_code_gen/configure_usersapi.go.bak ]; then
    cp ./post_code_gen/configure_usersapi.go.bak ./restapi/configure_usersapi.go
fi

if [ -f ./post_code_gen/configure_usersapi_test.go.bak ]; then
    cp ./post_code_gen/configure_usersapi_test.go.bak ./restapi/configure_usersapi_test.go
fi
if [ -f ./spec/.env ]; then
    cp ./spec/.env ./restapi/          #for test
    cp ./spec/.env ./restapi/custom/   #for test
    cp ./spec/.env ./.env    
fi