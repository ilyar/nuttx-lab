#!/usr/bin/env bash

set -o errexit

projectDir=$(cd "$(dirname "${0}")/.." && pwd)
# shellcheck source=script/util.sh
source "${projectDir}/script/util.sh" || source ./util.sh

usage() {
  println "POSIX-compliant bash script to manage toolchain for develop project"
  println "Usage: ${0} <option>"
  println "Options:"
  println "  -h this help"
  println "  -x enable debug mode (trace per command line in scripts)"
  println "  -c check requirements for environment"
  println "  -s setup environment ENV_TYPE=${ENV_TYPE}"
  println "  -d setup common deps"
}

commonSetup() {
  info "setup common"
  if [ ! -d nuttxspace ]; then
    nuttxVersion="10.3.0"
    nuttxOrg="https://github.com/apache"
    info "NuttX (v${nuttxVersion}) downloading"
    mkdir nuttxspace
    cd nuttxspace
    printf "${nuttxVersion}" > VERSION
    curl -L "${nuttxOrg}/incubator-nuttx/tarball/nuttx-${nuttxVersion}" -o nuttx.tar.gz
    tar zxf nuttx.tar.gz --one-top-level=nuttx --strip-components 1
    curl -L "${nuttxOrg}/incubator-nuttx-apps/tarball/nuttx-${nuttxVersion}" -o apps.tar.gz
    tar zxf apps.tar.gz --one-top-level=apps --strip-components 1
  else
    info "NuttX (v$(cat nuttxspace/VERSION)) exist"
  fi
}

debianSetup() {
  info "setup for platform debian"
  sudo apt-get update
  info "Installing prerequisites"
  sudo apt-get install -qq -y \
    bison flex gettext texinfo libncurses5-dev libncursesw5-dev \
    gperf automake libtool pkg-config build-essential gperf genromfs \
    libgmp-dev libmpc-dev libmpfr-dev libisl-dev binutils-dev libelf-dev \
    libexpat-dev gcc-multilib g++-multilib picocom u-boot-tools util-linux
  info "Installing KConfig frontend"
  sudo apt-get install -qq -y \
    kconfig-frontends
  info "Installing Toolchain"
  sudo apt-get install -qq -y \
    gcc-arm-none-eabi binutils-arm-none-eabi
}

macosSetup() {
  info "setup for platform macos"
  brew install x86_64-elf-gcc # Used by simulator
  brew install u-boot-tools # Some platform integrate with u-boot
}

windowsSetup() {
  info "setup for platform windows"
  choco install cygwin
  choco install cyg-get
  refreshenv
  cyg-get make
  cyg-get bison
  cyg-get libmpc-devel
  cyg-get gcc-core
  cyg-get byacc
  cyg-get automake-1.15
  cyg-get gcc-g++
  cyg-get gperf
  cyg-get libncurses-devel
  cyg-get flex
  cyg-get gdb
  cyg-get libmpfr-devel
  cyg-get git
  cyg-get unzip
  cyg-get zlib-devel
}

checkRequirements() {
  tryCommand git && git --version
  tryCommand cargo && cargo --version
  tryCommand make && println "make $(make --version | grep Make | cut -d" " -f3)"
}

checkEnvironment() {
  printENV
  tryCommand bash && println "bash ${BASH_VERSION}"
  checkRequirements
}

setupEnvironment() {
  checkRequirements

  case "$OS_FAMILY" in
  debian) debianSetup ;;
  macos) macosSetup ;;
  windows) windowsSetup ;;
  *) notReady "setup toolchain" ;;
  esac
}

main() {
  if [ "$(id -u)" == "0" ]; then fatal "Not running as root"; fi
  if [ -z "$*" ]; then usage; fi

  cmd=
  while getopts ":hxscd" flag; do
    case "${flag}" in
    x) set -o xtrace ;;
    s) cmd=setupEnvironment ;;
    c) cmd=checkEnvironment ;;
    d) cmd=commonSetup ;;
    ?) usage ;;
    esac
  done

  ${cmd}
}

main "$*"
