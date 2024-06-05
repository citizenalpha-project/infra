FROM golang:1.22.2-bookworm AS builder

ARG CHASQUID_TAG=v1.14.0

WORKDIR /src

ADD --checksum=sha256:9b8218f4ecc3c95380c7f1a3ab32156df6de261a24bd95962ab784f19137ab27 \
  https://github.com/albertito/chasquid/archive/refs/tags/${CHASQUID_TAG}.tar.gz .

RUN tar xzf ${CHASQUID_TAG}.tar.gz --strip-components=1

RUN go mod download && go mod verify

SHELL ["/bin/bash", "-c"]

RUN export VERSION="${CHASQUID_TAG:1}" && make chasquid chasquid-util smtp-check

FROM debian:bookworm-slim

COPY --from=builder \
  /src/chasquid \
  /src/chasquid-util \
  /src/smtp-check \
  /

COPY chasquid.conf /etc/chasquid/

ENTRYPOINT ["/chasquid", "-logtime"]
