#!/bin/bash
echo "Select the option"
echo -e "\e[32m========================================="
echo " PREPARE LOCAL env (do 1,2,3 first)"
echo "========================================="
echo "  1) Install build tools"
echo "  2) Create MySQL database"
echo -e "  3) Generate code with Swagger\e[0m"
echo "========================================="
echo " LOCAL test, doc and run"
echo "========================================="
echo "  4) Display OpenAPI Doc"
echo "  5) Validate Swagger API sepecification"
echo "  6) Run API"
echo "  7) Run Unit tests"
echo -e "\e[93m========================================="
echo " DOCKER env"
echo "========================================="
echo "  8) Create and run Docker image"
echo "     (mysql: golang_db, go: golang_app)"
echo -e "=========================================\e[0m"
echo "  Q) Quit" 

read n
case $n in
    1) ./scripts/build_tools_install.sh ;;
    2) ./scripts/mysql_db_create.sh ;;
    3) ./scripts/swagger_code_gen.sh ;;
    4) swagger serve ./spec/swagger.yaml ;;
    5) swagger validate ./spec/swagger.yaml ;;
    6) go run ./cmd/usersapi-server/main.go ;;
    7) ./scripts/run_unit_tests.sh ;;
    8) ./scripts/build_docker.sh ;;
    Q) exit ;;
    *) echo "invalid option" ;;
esac
