#!/bin/bash

RESULT="$(traceroute 8.8.8.8)"

FIRST_HOP="$(echo "${RESULT}" | head -2 | tail -1 | awk '{print $2}')"

if [ "${FIRST_HOP}" != "10.4.4.1" ]
then
  exit 1
fi

SECOND_HOP="$(echo "${RESULT}" | head -3 | tail -1 | awk '{print $2}')"

if [ "${SECOND_HOP}" == "10.5.5.1" ]
then
  exit 0
else
  exit 1
fi
