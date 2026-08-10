#!/usr/bin/env bash

readonly STATUS_OK=0
readonly STATUS_ALREADY_INSTALLED=10
readonly STATUS_DRY_RUN=20
readonly STATUS_FAILED=30

readonly REQUIRED_COMMANDS=(
    bash
    git
    grep
    find
    sort
    awk
    sed
)

readonly PACKAGE_MANAGER_COMMANDS=(
    apt
    apt-cache
    dpkg
)