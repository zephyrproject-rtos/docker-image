# docker-image
Docker image suitable for development, similar to what we have in CI.


This docker image can be built with

```
docker build -t zephyr_doc:v<tag> .
```

and can be used for development and building zephyr samples and tests,
for example:

```
docker run -ti -v <path to zephyr tree>:/workdir \
zephyr_doc:v<tag> /bin/bash
```

Then, follow the steps below to build a sample application:

```
cd samples/hello_world
mkdir build
cd build
cmake -DBOARD=qemu_x86 ..
make run
```

The image is also available on docker.io, so you can skip the build step
and directly pull from docker.io and build:

```
docker run -ti -v $HOME/Work/github/zephyr:/workdir
docker.io/zephyrprojectrtos/zephyr-build:latest /bin/bash
```

The environment is set and ready to go, no need to source zephyr-env.sh.

We have two toolchains installed:
- Zephyr SDK
- GNU Arm Embedded Toolchain

To switch, set ZEPHYR_TOOLCHAIN_VARIANT.
