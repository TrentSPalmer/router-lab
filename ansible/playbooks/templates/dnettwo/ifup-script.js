#!/bin/bash

default_dev="$(ip route | head -1 | awk '{print $5}')"
echo "${default_dev}"

if [ "${default_dev}" == "enp1s0" ]
then
  ip route del default via 10.55.44.1 dev enp1s0
fi

if [ "${default_dev}" != "enp7s0" ]
then
  ip route add default via 10.5.5.1 dev enp7s0
fi
