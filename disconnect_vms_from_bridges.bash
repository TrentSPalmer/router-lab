#!/bin/bash
# connect_vms_to_bridges.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"


function detach_running_vm() {
  local is_attached
  is_attached="$(virsh domiflist "${1}" | grep -c "${2}")"
  if [ "${is_attached}" == "1" ]
  then
    echo detaching "${1}" from "${2}"
    local mac_for_bridge
    mac_for_bridge="$(virsh domiflist "${1}" | grep "${2}" | awk '{print $5}')"
    virsh detach-interface "${1}" --mac "${mac_for_bridge}" --type network --config --live
    sleep 5
    detach_running_vm "${1}" "${2}"
  fi
  if [ "${is_attached}" == "0" ]
  then
    echo "${1}" is now detached from "${2}"
  fi
}

function detach_shut_off_vm() {
  local is_attached
  is_attached="$(virsh domiflist "${1}" | grep -c "${2}")"
  if [ "${is_attached}" == "1" ]
  then
    echo detaching "${1}" from "${2}"
    local mac_for_bridge
    mac_for_bridge="$(virsh domiflist "${1}" | grep "${2}" | awk '{print $5}')"
    virsh detach-interface "${1}" --mac "${mac_for_bridge}" --type network --config
    sleep 5
    detach_running_vm "${1}" "${2}"
  fi
  if [ "${is_attached}" == "0" ]
  then
    echo "${1}" is now detached from "${2}"
  fi
}

function detach_vm() {
  local is_running
  is_running="$(virsh dominfo "${1}" | grep State | awk '{print $2" "$3}')"
  if [ "${is_running}" == "running " ]
  then
    detach_running_vm "${1}" "${2}"
  fi
  if [ "${is_running}" == "shut off" ]
  then
    detach_shut_off_vm "${1}" "${2}"
  fi
}


function detach_vms() {
  for vm in "${MACHINES[@]}"
  do
    detach_vm "${vm}" "${BRIDGES[0]}"
    detach_vm "${vm}" "${BRIDGES[1]}"
  done
}

check_uid "${USER_UID}"

detach_vms
