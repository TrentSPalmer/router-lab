#!/bin/bash
# shutdown_vms.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"

function shutdown_vm() {
  local is_active 
  is_active="$(virsh list --state-running | awk '{print $2}' | grep "^${1}$" -c)"
  if [ "${is_active}" == "1" ]
  then
    virsh shutdown "${1}" 2>/dev/null
    sleep 3
    shutdown_vm "${1}"
  fi
}

function shutdown_vms() {
  export -f shutdown_vm
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'shutdown_vm "$@"' _ {}
}

check_uid "${USER_UID}"

shutdown_vms
