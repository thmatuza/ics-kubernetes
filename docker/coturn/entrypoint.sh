#!/bin/bash

echo "Starting TURN/STUN server"

turnserver -a -v -L 0.0.0.0 --server-name "${TURN_SERVER_NAME}" --user "${TURN_USERNAME}:${TURN_PASSWORD}" -p ${TURN_PORT} --min-port ${TURN_PORT_START} --max-port ${TURN_PORT_END} ${TURN_EXTRA}