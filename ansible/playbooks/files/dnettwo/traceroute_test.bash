#!/bin/bash

RESULT="$(traceroute 8.8.8.8)"

FIRST_HOP="$(echo "${RESULT}" | head -2 | tail -1 | awk '{print $2}')"

echo "${FIRST_HOP}"

if [ "${FIRST_HOP}" == "10.5.5.1" ]
then
  exit 0
else
  exit 1
fi