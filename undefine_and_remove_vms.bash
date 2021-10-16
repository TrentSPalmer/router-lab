#!/bin/bash
# undefine_and_remove_vms.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"

function destroy_vm() {
  local exists
  exists="$(virsh list --all | awk '{print $2}' | grep "^${1}$" -c)"
  if [ "${exists}" == "1" ]
  then
    virsh undefine --remove-all-storage "${1}"
  fi
}

function destroy_vms() {
  export -f destroy_vm
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'destroy_vm "$@"' _ {}
}

check_uid "${USER_UID}"

destroy_vms
echo ''
