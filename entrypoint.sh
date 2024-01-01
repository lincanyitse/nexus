#!/bin/bash

if [ -d "${NEXUS_DATA}" ]; then gosu root:root bash -c "chown nexus:nexus -R ${NEXUS_DATA}"; fi

exec "$@"
