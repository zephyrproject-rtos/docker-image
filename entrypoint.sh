#!/bin/bash

source /opt/toolchains/zephyr-sdk-0.14.1/environment-setup-x86_64-pokysdk-linux
source ~/ncs/zephyr/zephyr-env.sh

if (( $# > 0 )); then
  exec "$@"
else
  exec "/bin/bash"
fi
