#!/bin/bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT

function build() {

    MODULE_NAME=re-suspend.rpm
    WORK_CONTAINER="re-suspend-build-${BASHPID}"
    LOG_TAG=re-suspend

    function log_message() {
        local message="$*"
        printf '%s\n' "${message}"
        logger -t "${LOG_TAG}" -- "${message}"
    }

    function log_error() {
        local message="$*"
        printf '%s\n' "${message}" >&2
        logger -p user.err -t "${LOG_TAG}" -- "${message}"
    }

    cleanup() {
        log_message "${MODULE_NAME}: Removing the work toolbox..."
        toolbox rm --force "${WORK_CONTAINER}" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    log_message "${MODULE_NAME}: Creating work toolbox..."
    toolbox create --container "${WORK_CONTAINER}"
    log_message "${MODULE_NAME}: Installing tools into work toolbox..."
    toolbox run --container "${WORK_CONTAINER}" -- sudo dnf install -y rpm-build


    # Build RPM
    log_message "${MODULE_NAME}: Building RPM..."
    toolbox run --container "${WORK_CONTAINER}" -- \
        rpmbuild --define "_topdir ${REPO_ROOT}/rpmbuild" -ba \
        "${REPO_ROOT}/rpmbuild/SPECS/re-suspend.spec" \
        || return 1;


    return 0
}

build
