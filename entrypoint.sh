#!/bin/bash

source /opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/environment-setup-x86_64-pokysdk-linux
source ~/ncs/zephyr/zephyr-env.sh

if (( $# > 0 )); then
  exec "$@"
else
  exec "/bin/bash"
fi
