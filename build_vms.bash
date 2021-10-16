#!/bin/bash
# build_vms.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI}?no_verify=1"

function set_hostname() {
  echo setting host_name "${1}"
  local ip_address
  ip_address="$(virsh domifaddr "${1}" | tail -2 | head -1 | awk '{print $4}')"
  if [ "${ip_address:0:$(("${#SUBNET_FRAGMENT}"))}" != "${SUBNET_FRAGMENT}" ]
  then
    echo no dhcp lease yet, trying again for "${1}"
    sleep 15 && set_hostname "${1}"
  else
    local host_name
    host_name="$(ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" 'cat /etc/hostname' 2>/dev/null)"
    echo host_name is found to be "${host_name}"
    if [ "${host_name}" != "${1}" ]
    then
      echo "${host_name}" is wrong, changing to "${1}"
      # shellcheck disable=SC2027,SC2086
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "echo "${1}" > /etc/hostname"
      # shellcheck disable=SC2027,SC2086
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "sed -i 's/"${ORIGINAL}"/"${1}"/g' /etc/hosts 2>/dev/null"
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" 'systemctl reboot'
      sleep 25
    fi
  fi
}

function confirm_hostname() {
  echo confirming host_name "${1}"
  local ip_address
  ip_address="$(virsh domifaddr "${1}" | tail -2 | head -1 | awk '{print $4}')"
  if [ "${ip_address:0:$(("${#SUBNET_FRAGMENT}"))}" != "${SUBNET_FRAGMENT}" ]
  then
    sleep 5
    confirm_hostname "${1}"
  else
    local host_name
    host_name="$(ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" 'hostname' 2>/dev/null)"
    if [ "${host_name}" != "${1}" ]
    then
      set_hostname "${1}"
      sleep 1
      confirm_hostname "${1}"
    fi
  fi
}

function confirm_hostname_in_hosts() {
  echo confirming host_name_in_hosts "${1}"
  local ip_address
  ip_address="$(virsh domifaddr "${1}" | tail -2 | head -1 | awk '{print $4}')"
  if [ "${ip_address:0:$(("${#SUBNET_FRAGMENT}"))}" != "${SUBNET_FRAGMENT}" ]
  then
    sleep 5
    confirm_hostname_in_hosts "${1}"
  else
    local host_is_in_hosts 
    # shellcheck disable=SC2027,SC2086
    host_is_in_hosts="$(ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "grep "${1}" -c /etc/hosts")"
    if [ "${host_is_in_hosts}" == "0" ]
    then
      # shellcheck disable=SC2027,SC2086
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "sed -i 's/"${ORIGINAL}"/"${1}"/g' /etc/hosts 2>/dev/null"
      confirm_hostname_in_hosts "${1}"
    fi
  fi
}

function reset_machine_id() {
  echo reset_machine_id "${1}"
  local ip_address
  ip_address="$(virsh domifaddr "${1}" | tail -2 | head -1 | awk '{print $4}')"
  if [ "${ip_address:0:$(("${#SUBNET_FRAGMENT}"))}" != "${SUBNET_FRAGMENT}" ]
  then
    sleep 2
    reset_host_ssh_keys "${1}"
  else
    local existing_machine_id
    existing_machine_id="$(ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "cat /etc/machine-id")"
    if [ "${existing_machine_id}" == "${ORIGINAL_MACHINE_ID}" ]
    then
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "rm -v /etc/machine-id && rm -v /var/lib/dbus/machine-id"
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "dbus-uuidgen --ensure && systemd-machine-id-setup"
      reset_machine_id "${1}"
    else
      echo "${1}" has a new machine-id
    fi
  fi
}

function reset_host_ssh_keys() {
  echo reset_host_ssh_keys "${1}"
  local ip_address
  ip_address="$(virsh domifaddr "${1}" | tail -2 | head -1 | awk '{print $4}')"
  if [ "${ip_address:0:$(("${#SUBNET_FRAGMENT}"))}" != "${SUBNET_FRAGMENT}" ]
  then
    sleep 2
    reset_host_ssh_keys "${1}"
  else
    local existing_ED25519PUB
    existing_ED25519PUB="$(ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "cat /etc/ssh/ssh_host_ed25519_key.pub")"
    if [ "${existing_ED25519PUB}" == "${ORIGINAL_SSH_ED25519PUB}" ]
    then
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "rm -v /etc/ssh/ssh_host_* && ssh-keygen -A"
      ssh -o "StrictHostKeyChecking no" "${ip_address:0:-3}" "systemctl restart sshd"
      rm ~/.ssh/known_hosts
      reset_host_ssh_keys "${1}"
    else
      echo "${1}" has new ssh host keys
    fi
  fi
}

function create_vm() {
  local exists
  exists="$(virsh list --all | awk '{print $2}' | grep "^${1}$" -c)"
  if [ "${exists}" == "0" ]
  then
    virt-clone --original "${ORIGINAL}" --name "${1}" --auto-clone
  fi
  start_vm "${1}"
}

function reset_hosts_ssh_keys() {
  export -f reset_host_ssh_keys
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'reset_host_ssh_keys "$@"' _ {}
}

function reset_machine_ids() {
  export -f reset_machine_id
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'reset_machine_id "$@"' _ {}
}

function confirm_hostnames_in_hosts() {
  export -f confirm_hostname_in_hosts
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'confirm_hostname_in_hosts "$@"' _ {}
}

function confirm_hostnames() {
  export -f confirm_hostname
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'confirm_hostname "$@"' _ {}
}

function set_hostnames() {
  export -f set_hostname
  printf "%s\n" "${MACHINES[@]}" | xargs -P 8 -I {} bash -c 'set_hostname "$@"' _ {}
}

function build_vms() {
  for vm in "${MACHINES[@]}"
  do
    create_vm "${vm}"
  done
}

check_uid "0"

rm ~/.ssh/known_hosts

build_vms
set_hostnames
confirm_hostnames
confirm_hostnames_in_hosts
reset_hosts_ssh_keys
rm ~/.ssh/known_hosts

reset_machine_ids
