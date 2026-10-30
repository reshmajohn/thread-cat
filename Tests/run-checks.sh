#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build
xcrun swiftc -swift-version 6 -module-cache-path build/module-cache \
    ThreadCat/Thought.swift ThreadCat/ThoughtStore.swift Tests/ThoughtStoreChecks.swift \
    -o build/ThoughtStoreChecks
build/ThoughtStoreChecks
