#!/bin/bash

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

error () {
  printf "\r\033[2K  [\033[0;31mERROR\033[0m] $1\n"
}

isRunningOnMac () {
  if [ "$(uname)" = "Darwin" ] ; then
    return 0
  else
    return 1
  fi
}

isRunningOnWSL () {
  if [ -f /proc/version ] && grep -q microsoft /proc/version; then
    return 0
  else
    return 1
  fi
}

isRunningOnLinux () {
  if [ "$(uname)" = "Linux" ] ; then
    return 0
  else
    return 1
  fi
}