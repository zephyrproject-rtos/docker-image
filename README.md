# Zephyr Docker Images

This repository contains the Dockerfiles for the following images:

- **CI Base Image (_ci-base_):** contains all tools required for CI operation, except the Zephyr
  SDK.
- **CI Image (_ci_):** contains everything in the `ci-base` image and the Zephyr SDK.
- **Developer Image (_zephyr-build_):** includes additional tools that can be useful for Zephyr
  development.

## Developer Docker Image

### Overview

The Developer docker image includes all tools included in the CI image as well as the additional
tools that can be useful for Zephyr development, such as the VNC server for testing display sample
applications.

The Base docker images should be used to build custom docker images with 3rd party toolchains and tooling.

These images include the [Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng), which supports
building most Zephyr targets.

### Installation

#### Using Pre-built Developer Docker Image

The pre-built developer docker image is available on both GitHub Container Registry (`ghcr.io`) and
DockerHub (`docker.io`).

For Zephyr 3.7 LTS, use the `v0.26-branch` or the latest `v0.26.x` release Docker image.

##### GitHub Container Registry (`ghcr.io`)

###### Current Zephyr versions

```
docker run -ti -v $HOME/Work/zephyrproject:/workdir \
           ghcr.io/zephyrproject-rtos/zephyr-build:main
```

###### Zephyr 3.7 LTS

```
docker run -ti -v $HOME/Work/zephyrproject:/workdir \
           ghcr.io/zephyrproject-rtos/zephyr-build:v0.26-branch
```

##### DockerHub (`docker.io`)

###### Current Zephyr versions

```
docker run -ti -v $HOME/Work/zephyrproject:/workdir \
           docker.io/zephyrprojectrtos/zephyr-build:main
```

###### Zephyr 3.7 LTS

```
docker run -ti -v $HOME/Work/zephyrproject:/workdir \
           docker.io/zephyrprojectrtos/zephyr-build:v0.26-branch
```

#### Building Developer Docker Image

The developer docker image can be built using the following commands:

```
docker build -f Dockerfile.base --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t zephyr-ci-base:v<tag> .
docker build -f Dockerfile.ci --build-arg BASE_IMAGE=zephyr-ci-base:v<tag> -t zephyr-ci:v<tag> .
docker build -f Dockerfile.devel --build-arg BASE_IMAGE=zephyr-ci:v<tag> -t zephyr-build:v<tag> .
```

It can be used for building Zephyr samples and tests by mounting the Zephyr workspace into it:

```
docker run -ti -v <path to zephyr workspace>:/workdir zephyr-build:v<tag>
```

#### Using SSH Agent with Docker Image

The docker images can be built to use the SSH agent on the host to provide authorization
to assets like restricted git repos.  To do this there are a few requirements.  One of which
is that the user name of the processes inside the docker container must match the real user
name on the host.  The USERNAME build argument can be passed into the build process to override
the default user name.  Note that all three images need to be built locally with this USERNAME
argument set correctly.

```
docker build -f Dockerfile.base \
   --build-arg UID=$(id -u) \
   --build-arg GID=$(id -g) \
   --build-arg USERNAME=$(id -u -n) \
    -t ci-base:<tag> .
```
```
docker build -f Dockerfile.ci \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --build-arg USERNAME=$(id -u -n) \
    --build-arg BASE_IMAGE=ci-base:v4.0-branch \
    -t ci:<tag> .
```
```
 docker build -f Dockerfile.devel \
     --build-arg UID=$(id -u) \
     --build-arg GID=$(id -g) \
     --build-arg USERNAME=$(id -u -n) \
     --build-arg BASE_IMAGE=ci:v4.0-branch \
     -t devel:<tag> .
```

Then when running the ci or devel image there are additional command line arguments to
connect the host ssh-agent ports to the ssh-agent ports inside the container.

```
docker run -ti \
    -v $HOME/Work/zephyrproject:/workdir \
    --mount type=bind,src=$SSH_AUTH_SOCK,target=/run/host-services/ssh-auth.sock \
    --env SSH_AUTH_SOCK="/run/host-services/ssh-auth.sock" \
    devel:<tag>
```

### Usage

#### Building a sample application

Follow the steps below to build and run a sample application:

```
west build -b qemu_x86 samples/hello_world
west build -t run
```

#### Building display sample applications

It is possible to build and run the _native POSIX_ sample applications that produce display outputs
by connecting to the Docker instance using a VNC client.

In order to allow the VNC client to connect to the Docker instance, the port 5900 needs to be
forwarded to the host:

```
docker run -ti -p 5900:5900 -v <path to zephyr workspace>:/workdir zephyr-build:v<tag>
```

Follow the steps below to build a display sample application for the _native POSIX_ board:

```
west build -b native_posix samples/subsys/display/cfb
west build -t run
```

The application display output can be observed by connecting a VNC client to _localhost_ at the
port _5900_. The default VNC password is _zephyr_.

On a Ubuntu host, this can be done by running the following command:

```
vncviewer localhost:5900
```
