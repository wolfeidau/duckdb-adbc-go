# syntax=docker/dockerfile:1
FROM golang:1.21

ARG DUCKDB_VERSION

WORKDIR /src
ADD go.mod go.sum /src/
RUN go mod download
ADD main.go /src/
RUN go build -ldflags="-X 'main.driver=/lib/aarch64-linux-gnu/libduckdb.so'" -o /bin/main

FROM debian:bookworm

ARG DUCKDB_VERSION

COPY --from=0 /bin/main /bin/main
ADD lib/$DUCKDB_VERSION/linux-aarch64/libduckdb.so /usr/lib/aarch64-linux-gnu/
ADD extensions/$DUCKDB_VERSION/linux_arm64/ /extensions/$DUCKDB_VERSION/linux_arm64/
ADD data /data/

CMD ["/bin/main"]