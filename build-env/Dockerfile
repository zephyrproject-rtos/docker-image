FROM ubuntu:18.04

ARG ZSDK_VERSION=0.11.2

# install packages toolchain:
ADD install-prereqs.sh /root/install-prereqs.sh
RUN /root/install-prereqs.sh && rm /root/install-prereqs.sh

ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

WORKDIR /workdir
