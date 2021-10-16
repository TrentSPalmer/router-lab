#!/bin/bash
# remove_bridge_networks.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"


function disable_autostart_bridge_network() {
  local will_autostart
  will_autostart="$(virsh net-info "${1}" | grep Autostart | awk '{print $2}')"
  if [ "${will_autostart}" == "yes" ]
  then
    echo disebling autostart for "${1}"
    virsh net-autostart --disable "${1}"
    disable_autostart_bridge_network "${1}"
  fi
  if [ "${will_autostart}" == "no" ]
  then
    echo "${1}" is now unmarked autostart
  fi
}

function stop_bridge_network() {
  local is_running
  is_running="$(virsh net-info "${1}" | grep Active | awk '{print $2}')"
  if [ "${is_running}" == "yes" ]
  then
    echo destroyinging "${1}" 
    virsh net-destroy "${1}"
    stop_bridge_network "${1}"
  fi
  if [ "${is_running}" == "no" ]
  then
    echo "${1}" is now not running
  fi
}

function undefine_bridge_network() {
    local is_defined
    is_defined="$(virsh net-list --all | grep -c "${1}")"
    if [ "${is_defined}" == "1" ]
    then
      echo undefining "${1}" bridge network
      virsh net-undefine "${1}"
      undefine_bridge_network "${1}"
    fi
    if [ "${is_defined}" == "0" ]
    then
      echo bridge network "${1}" no longer exists
      echo xml config presumably removed from "/etc/libvirt/qemu/networks/${1}.xml"
    fi
}

function disable_autostart_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    disable_autostart_bridge_network "${bridge}"
  done
}

function stop_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    stop_bridge_network "${bridge}"
  done
}

function undefine_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    undefine_bridge_network "${bridge}"
  done
}

check_uid "${USER_UID}"

disable_autostart_bridge_networks
stop_bridge_networks
undefine_bridge_networks
