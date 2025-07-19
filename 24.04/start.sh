#!/bin/bash

# Global Vars
DOWNLOAD_PATH=$HOME/Downloads/tmp
OS_VERSION=24.04 LTS (KUBUNTU)
VERSION=0.0.1

# Fetch all the named args
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        v="${1/--/}"
        declare $v="$2"
   fi

  shift
done

clear

echo "----------------------------------------------------"
echo "Welcome to bunnychow $OS_VERSION (v$VERSION)"
echo "=> The following will be installed:"
echo " -> debs: $debs"
echo " -> flatpaks: $flatpaks"
if [ -n "$apt_install" ]; then
  echo "=> the following apt install(s) will be invoked"
  echo " -> $apt_install"
fi
if [ -n "$apt_remove" ]; then
  echo "=> the following apt remove(s) will be invoked"
  echo " -> $apt_remove"
fi
if [[ $debloat == "yes" ]]; then
  echo "=> snap packages will be removed"
fi
if [[ $neaten == "yes" ]]; then
  echo "=> the shell will also be neatened"
fi
if [[ $theme == "dark" ]]; then
  echo "=> dark theme will be set"
fi
echo "----------------------------------------------------"

sudo apt-get update
sudo apt-get upgrade -yq