#!/bin/bash

check_var() {
  if [[ ! -v $1 || -z $(eval echo \$${1}) ]]; then
    echo "Missing environment variable $1 : $2"
    ((++badVars))
  fi
}

resolve_vars() {
    if [[ $badVars > 0 ]]; then
      echo "
There were one or more missing build variables"
      exit 1
    fi
}

do_release() {
  check_var MVN_RELEASE_TAG
  check_var MVN_RELEASE_DEV_VER
  check_var MVN_RELEASE_USER_EMAIL
  check_var MVN_RELEASE_USER_NAME
  resolve_vars

  set -e

  git config user.email "${MVN_RELEASE_USER_EMAIL}"
  git config user.name "${MVN_RELEASE_USER_NAME}"

  mvn -B -Dtag=${MVN_RELEASE_TAG} release:prepare \
               -DreleaseVersion=${MVN_RELEASE_VER} \
               -DdevelopmentVersion=${MVN_RELEASE_DEV_VER}

  mvn -B -s settings.xml release:perform

  mvn release:clean

}

while getopts t: var ; do
  case $var in
    t)
      build_tag=$OPTARG ;;
  esac
done

if [[ -n $build_tag ]]; then

  IFS='/' read -r -a parts <<< "$build_tag"

  if [ ${#parts[*]} != 3 ]; then
    echo "ERROR: -t needs to be trigger/tag/dev_ver"
    exit 1
  fi
  MVN_RELEASE_TAG="v${parts[1]}"
  MVN_RELEASE_VER=${parts[1]}
  MVN_RELEASE_DEV_VER=${parts[2]}

  do_release
elif [[ -v MVN_RELEASE_VER ]]; then
  do_release
fi
