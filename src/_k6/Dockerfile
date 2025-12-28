FROM grafana/k6:latest

# Install jq for JSON processing in summary scripts
USER root
RUN apk add --no-cache jq bc
USER k6
