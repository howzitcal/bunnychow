#!/bin/bash

# Global Vars
DOWNLOAD_PATH=$HOME/Downloads/tmp
OS_VERSION=24.04 LTS
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

sudo apt-get update
sudo apt-get upgrade -yq