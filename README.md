# Zephyr Docker Image

This repository contains a single Dockerfile that can be used for development or CI.

### Overview

The Docker image includes tools that can be useful for Zephyr development.

These images include the [Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng), which supports
building most Zephyr targets.

### Installation

#### Using Pre-built Developer Docker Image

The pre-built docker image is available on DockerHub (`docker.io`).

**DockerHub (`docker.io`)**

```
docker run -ti -v $HOME/Work/zephyrproject:/workdir \
           docker.io/zephyrprojectrtos/zephyr-build:latest
```

#### Building Developer Docker Image

The docker image can be built using the following command:

```
docker build -f Dockerfile --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t zephyr-build:v<tag> .
```

It can be used for building Zephyr samples and tests by mounting the Zephyr workspace into it:

```
docker run -ti -v <path to zephyr workspace>:/workdir zephyr-build:v<tag>
```

It can be used for CI/CD or one-off builds by mounting the Zephyr workspace into it and passing a command:

```
docker run -rm -v <path to zephyr workspace>:/workdir zephyr-build:v<tag> west build -b qemu_x86
```

### Usage

#### Building a sample application

Follow the steps below to build and run a sample application:

```
west build -b qemu_x86 samples/hello_world
west build -t run
```
