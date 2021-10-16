#!/bin/bash
# rebuild_known_hosts.bash
# shellcheck source=/dev/null

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR/env.bash"


check_uid "${USER_UID}"

rm ~/.ssh/known_hosts

for vm in "${MACHINES[@]}"
do
  ssh -o "StrictHostKeyChecking no" "${vm}" "hostname"
done

ssh -o "StrictHostKeyChecking no" "${SUBNET_FRAGMENT}.1" "hostname"
