#!/usr/bin/env bash

set -o errexit
set -o pipefail

fail() {
    echo "$@" >&2
    exit 1
}

export MC_JAR="/opt/minecraft/$(ls minecraft-server\.*\.jar)"

echo "Starting minecraft server"
java ${JAVA_ARGS} -jar "${MC_JAR}" nogui || fail "failed to start $MC_JAR"
