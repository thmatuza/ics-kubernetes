FROM ubuntu:16.04

RUN apt-get update && apt-get -y install coturn

ENV TURN_PORT 3478
ENV TURN_PORT_START 49152
ENV TURN_PORT_END 65535
ENV TURN_USERNAME kurento
ENV TURN_PASSWORD kurento
ENV TURN_SERVER_NAME collabo

# Copy coturn entrypoint
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh