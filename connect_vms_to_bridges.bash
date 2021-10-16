#!/bin/bash
# connect_vms_to_bridges.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"

function connect_vm_to_bridge() {
  # vm="${1}" ; bridge="${2}"
  local is_running
  is_running="$(virsh dominfo "${1}" | grep State | awk '{print $2" "$3}')"
  if [ "${is_running}" != "shut off" ]
  then
    echo "${1}" not shut off
    exit
  fi
  local is_attached
  is_attached="$(virsh domiflist "${1}" | grep -c "${2}")"
  if [ "${is_attached}" == "0" ]
  then
    echo attaching "${1}" to "${2}"
    virsh attach-interface "${1}" --type network --source "${2}" --model virtio --config
    connect_upper_bridge "${1}" "${2}"
  fi
  if [ "${is_attached}" == "1" ]
  then
    echo "${1}" is now attached to "${2}"
  fi
}


function connect_upper_bridge() {
  for vm in "${MACHINES[@]:0:2}"
  do
    connect_vm_to_bridge "${vm}" "${BRIDGES[0]}"
  done
}

function connect_lower_bridge() {
  for vm in "${MACHINES[@]:1}"
  do
    connect_vm_to_bridge "${vm}" "${BRIDGES[1]}"
  done
}

check_uid "${USER_UID}"

connect_upper_bridge
connect_lower_bridge
