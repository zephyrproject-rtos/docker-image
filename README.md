# docker-image
Docker image suitable for development, similar to what we have in CI.


This docker image can be built with

```
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t zephyr_doc:v<tag> .
```

and can be used for development and building zephyr samples and tests,
for example:

```
docker run -ti -v <path to zephyr tree>:/workdir zephyr_doc:v<tag>
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
docker run -ti -v $HOME/Work/github/zephyr:/workdir \
docker.io/zephyrprojectrtos/zephyr-build:latest
```

The environment is set and ready to go, no need to source zephyr-env.sh.

We have two toolchains installed:
- Zephyr SDK
- GNU Arm Embedded Toolchain

To switch, set ZEPHYR_TOOLCHAIN_VARIANT.

Further it is possible to run _native POSIX_ samples that require a display
and check the display output via a VNC client. To allow the VNC client to
connect to the docker instance port 5900 needs to be forwarded to the host,
for example:

```
docker run -ti -p 5900:5900 -v <path to zephyr tree>:/workdir zephyr_doc:v<tag>
```

Then, follow the steps below to build a display sample application for the
_native POSIX_ board:

```
cd samples/display/cfb
mkdir build
cd build
cmake -DBOARD=native_posix -GNinja ..
ninja run
```

The result can be observed by connecting a VNC client to _localhost_ at port
_5900_, the default VNC password is _zephyr_.

For example on a Ubuntu host system:

```
vncviewer localhost:5900
```



