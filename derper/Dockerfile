FROM golang:alpine AS builder
RUN go install tailscale.com/cmd/derper@latest

FROM alpine:latest
WORKDIR /app
COPY --from=builder /go/bin/derper .
RUN apk add --no-cache ca-certificates iptables iproute2

ENTRYPOINT ["/app/derper"]