#!/bin/bash

for (( i=1; i<=$#; i++ )); do
  if [[ "${!i}" = "--log" ]]; then
    LOG=true
  elif [[ "${!i}" = "--environment" ]]; then
    USE_ENVIRONMENT="$(($i+1))"
    ENVIRONMENT="${!USE_ENVIRONMENT}"
  fi
done

source ./.ibs/build.ibs

function log {
  if [[ "${LOG}" ]]; then
    echo "${@}"
  fi
}

function warn {
  if [[ "${LOG}" ]]; then
    echo -e "\033[1;33m${@}\033[0m"
  fi
}

function error {
  echo -e "\033[0;31m${@}\033[0m"
  exit 1
}

if [[ -f ./build.ibs ]]; then
  source ./build.ibs
fi

function _environment {
  if [[ "${USE_ENVIRONMENT}" ]]; then
    source ./ibs.env
    if [[ "${ENVIRONMENT}" ]]; then
      source "./ibs.${ENVIRONMENT}.env"
    fi
  fi
  echo "${ENV}"
}

function _build {
  :
}

function _test {
  :
}

function _analyze {
  :
}
preEnvironmentHook
_environment
postEnvironmentHook
preBuildHook
_build
postBuildHook
preTestHook
_test
postTestHook
preAnalysisHook
_analyze
postAnalysisHook
