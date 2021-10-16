#!/bin/bash
# build_vms.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"

function start_vms() {
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'start_vm "$@"' _ {}
}

check_uid "${USER_UID}"

start_vms
