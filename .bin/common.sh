#!/bin/bash

info () {
  printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

isRunningOnMac () {
  if [ "$(uname)" != "Darwin" ] ; then
    echo "Not macOS!"
    exit 1
  fi
}