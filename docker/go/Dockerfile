FROM golang:latest
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
ADD . /go/src/3fstest
RUN go get "github.com/go-sql-driver/mysql"
RUN ls -la /go/src/3fstest
WORKDIR /go/src/3fstest
RUN ./scripts/build_tools_install.sh
RUN ./scripts/build_vendor.sh
RUN chmod a+x /go/src/3fstest
ENV GOBIN $GOPATH/bin

RUN go build ./cmd/usersapi-server/
CMD $GOBIN/usersapi-server --port=3000 --host="0.0.0.0"

EXPOSE 3000