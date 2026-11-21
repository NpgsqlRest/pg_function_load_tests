FROM grafana/k6:2.4.0

# Install jq for JSON processing in summary scripts
USER root
RUN apk add --no-cache jq bc docker-cli
USER k6
