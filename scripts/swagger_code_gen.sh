#!/bin/bash

set -e

rm -rf cmd/
rm -rf restapi/
rm -rf models/
rm -rf vendor/

swagger generate server -A usersapi -f ./spec/swagger.yaml --model-package=models 

#./scripts/copy_post_code_gen.sh

rm -rf client/
swagger generate client -f ./spec/swagger.yaml -A  usersapi  
