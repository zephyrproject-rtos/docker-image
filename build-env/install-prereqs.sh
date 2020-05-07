#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

ZSDK_VERSION=0.11.2

# install prerequisite packages:
dpkg --add-architecture i386

apt-get update && apt-get upgrade -y

DEBIAN_FRONTEND=noniteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    ccache \
    cmake \
    device-tree-compiler \
    dfu-util \
    file \
    gcc \
    gcc-multilib \
    git \
    gnupg \
    g++-multilib \
    gperf \
    libsdl2-dev \
    make \
    ninja-build \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-tk \
    python3-wheel \
    wget \
    xz-utils

# install the latest CMake:
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add -
sh -c "echo 'deb https://apt.kitware.com/ubuntu/ bionic main' > /etc/apt/sources.list.d/cmake.list"

apt update && apt-get install -y cmake

# install west:
pip3 install -U west

# install Zephyr SDK:
wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-setup.run" && \
    sh "zephyr-sdk-${ZSDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
    rm "zephyr-sdk-${ZSDK_VERSION}-setup.run"

#
# Grab any other python dependencies. TODO: should we pull a particular version, instead of master?
#
REQTS_URL="https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts"
for file in requirements requirements-base requirements-build-test requirements-doc requirements-run-test requirements-extras
do
    wget -q "$REQTS_URL"/"$file".txt
done

pip3 install -r requirements.txt 

for file in requirements requirements-base requirements-build-test requirements-doc requirements-run-test requirements-extras
do
    rm "$file".txt
done
