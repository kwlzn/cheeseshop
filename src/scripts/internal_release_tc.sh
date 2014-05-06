#!/usr/bin/env bash

set -o errexit

HERE=$(
  cd $(dirname $0)
  pwd
)
source "$HERE/common.sh"


# The python used to setup the initial virtualenv.
BOOTSTRAP_PY=${BOOTSTRAP_PY:-$(which python)}

VENV_VERSION=${VENV_VERSION:-1.11.4}
VENV_URL=https://pypi.python.org/packages/source/v/virtualenv


OS_COMMONS_ORIGIN=https://github.com/twitter/commons.git
OS_COMMONS_STAGING=$HOME/.pantsbuild.pants.release/os_commons

# TODO(John Sirois): For now, the requirements list must be kept in sync with pantsbuild/pants
# needs manually
PANTS_DEPS=(
  src/python/twitter/common/collections
  src/python/twitter/common/config
  src/python/twitter/common/confluence
  src/python/twitter/common/contextutil
  src/python/twitter/common/decorators
  src/python/twitter/common/lang
  src/python/twitter/common/log
  src/python/twitter/common/process
  src/python/twitter/common/python
  src/python/twitter/common/quantity
  src/python/twitter/common/threading
  src/python/twitter/common/util
)



ROOT=$(find_root)

function usage() {
  echo "Builds release sdists from open source twitter/commons."
  echo
  echo "Usage: $0 (-h|-s [master])"
  echo " -h           print out this help message"
  echo " -s [sha]     the sha to build twitter/commons from; by default the HEAD of origin/master"

  if (( $# > 0 )); then
    die "$@"
  else
    exit 0
  fi
}

while getopts "hs:" opt; do
  case ${opt} in
    h) usage ;;
    s) sha=${OPTARG} ;;
    *) usage "Invalid option: -${OPTARG}" ;;
  esac
done

sha=${sha:-origin/master}
destination=${ROOT}/third_party/twitter-commons/${sha}



banner "Grabbing open source twitter/commons at ${sha}"

function have_os_pants_clone() {
  (
    cd ${OS_COMMONS_STAGING} && \
    [[ "$(git rev-parse --show-toplevel 2>/dev/null)" == "${OS_COMMONS_STAGING}" ]] && \
    [[ "$(git config --get remote.origin.url)" == "${OS_COMMONS_ORIGIN}" ]]
  )
}

if have_os_pants_clone; then
  banner "Updating ${OS_COMMONS_STAGING} from ${OS_COMMONS_ORIGIN}"
  (
    cd ${OS_COMMONS_STAGING} && \
    git fetch && \
    git reset --hard ${sha} && \
    git clean -fdx
  ) || die "Failed to refresh open source twitter/commons clone at ${OS_COMMONS_STAGING}"
else
  banner "Cloning ${OS_COMMONS_ORIGIN} to ${OS_COMMONS_STAGING}"
  (
    rm -rf ${OS_COMMONS_STAGING} && \
    mkdir -p ${OS_COMMONS_STAGING} && \
    git clone ${OS_COMMONS_ORIGIN} ${OS_COMMONS_STAGING} || \
    cd ${OS_COMMONS_STAGING} && \
    git log -1 && \
    git checkout ${sha}
  ) || die "Failed to clone open source twitter/commons clone to ${OS_COMMONS_STAGING}"
fi



banner "Building sdists for open source twitter/commons at ${sha}"
(
  cd ${OS_COMMONS_STAGING} && \
  ./build-support/python/clean.sh && \
  (
    for dep in ${PANTS_DEPS[@]}
    do
      ./pants setup_py --recursive ${dep} || die "Failed to build $dep"
    done
  ) && ([[ -d ${destination} ]] || mkdir -p ${destination}) && \
  cp -v dist/*.tar.gz ${destination}/
) || die "Failed to build open source twitter/commons distributions"



banner "Building eggs from open source twitter/commons sdists at ${sha}"
(
  cd ${OS_COMMONS_STAGING}/dist && \
  (
  for sdist in *.tar.gz
    do
      tar xfz ${sdist}
      cd ${sdist%".tar.gz"}
      python setup.py bdist_egg
      cp dist/*.egg ../
      cd ../
    done
  ) && cd ../ && \
  ([[ -d ${destination}/dist ]] || mkdir -p ${destination}/dist) && \
  pwd && \
  cp -v dist/*.egg ${destination}/dist
) || die "Failed to build open source twitter/commons eggs"



banner "Updating cheeseshop"
(
  ${ROOT}/third_party/twitter-commons/rebuild-index.sh ${sha} && \
  git add third_party/twitter-commons && \
  git commit -am "Publish twitter/commons ${sha}" && \
  git push origin HEAD
)
