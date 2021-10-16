#!/bin/bash
# define_bridge_networks.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"


function define_bridge_network() {
    local is_defined
    is_defined="$(virsh net-list --all | grep -c "${1}")"
    if [ "${is_defined}" == "0" ]
    then
      echo creating "${1}" bridge network
      virsh net-define "${SCRIPT_DIR}/${1}.xml"
      define_bridge_network "${1}"
    fi
    if [ "${is_defined}" == "1" ]
    then
      echo bridge network "${1}" exists
      echo xml config presumably written to "/etc/libvirt/qemu/networks/${1}.xml"
    fi
}

function start_bridge_network() {
  local is_running
  is_running="$(virsh net-info "${1}" | grep Active | awk '{print $2}')"
  if [ "${is_running}" == "no" ]
  then
    echo starting "${1}" 
    virsh net-start "${1}"
    start_bridge_network "${1}"
  fi
  if [ "${is_running}" == "yes" ]
  then
    echo "${1}" is now running
  fi
}

function autostart_bridge_network() {
  local will_autostart
  will_autostart="$(virsh net-info "${1}" | grep Autostart | awk '{print $2}')"
  if [ "${will_autostart}" == "no" ]
  then
    echo enable autostart for "${1}"
    virsh net-autostart "${1}"
    autostart_bridge_network "${1}"
  fi
  if [ "${will_autostart}" == "yes" ]
  then
    echo "${1}" is now marked autostart
  fi
}

function define_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    define_bridge_network "${bridge}"
  done
}

function start_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    start_bridge_network "${bridge}"
  done
}

function autostart_bridge_networks() {
  for bridge in  "${BRIDGES[@]}"
  do
    autostart_bridge_network "${bridge}"
  done
}

check_uid "${USER_UID}"

define_bridge_networks
start_bridge_networks
autostart_bridge_networks
