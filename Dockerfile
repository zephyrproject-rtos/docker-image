FROM ubuntu:18.04

ARG ZSDK_VERSION=0.9.5
ARG GCC_ARM_NAME=gcc-arm-none-eabi-7-2018-q2-update

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
	autoconf \
	automake \
	build-essential \
	ccache \
	cmake \
	device-tree-compiler \
	dfu-util \
	doxygen \
	file \
	g++ \
	gcc \
	gcc-multilib \
	gcovr \
	git \
	git-core \
	gperf \
	iproute2 \
	lcov \
	libglib2.0-dev \
	libpcap-dev \
	libsdl2-dev:i386 \
	libtool \
	locales \
	make \
	net-tools \
	ninja-build \
	openbox \
	pkg-config \
	python3-pip \
	python3-ply \
	python3-setuptools \
	python-xdg \
	qemu \
	socat \
	sudo \
	texinfo \
	valgrind \
	wget \
	x11vnc \
	xvfb \
	xz-utils && \
	wget -O dtc.deb http://security.ubuntu.com/ubuntu/pool/main/d/device-tree-compiler/device-tree-compiler_1.4.7-1_amd64.deb && \
	dpkg -i dtc.deb && \
	rm dtc.deb && \
	rm -rf /var/lib/apt/lists/*

RUN wget -q https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install wheel &&\
	pip3 install west &&\
	pip3 install -r requirements.txt && \
	pip3 install sh

RUN wget -q "https://github.com/zephyrproject-rtos/meta-zephyr-sdk/releases/download/${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-setup.run" && \
	sh "zephyr-sdk-${ZSDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
	rm "zephyr-sdk-${ZSDK_VERSION}-setup.run"

RUN wget -q https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2018q2/${GCC_ARM_NAME}-linux.tar.bz2  && \
	tar xf ${GCC_ARM_NAME}-linux.tar.bz2 && \
	rm -f ${GCC_ARM_NAME}-linux.tar.bz2 && \
	mv ${GCC_ARM_NAME} /opt/toolchains/${GCC_ARM_NAME}

RUN useradd -m -G plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
ENV ZEPHYR_BASE=/workdir
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DISPLAY=:0

RUN chown -R user:user /home/user

ADD ./entrypoint.sh /home/user/entrypoint.sh

EXPOSE 5900

ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD ["/bin/bash"]
USER user
WORKDIR /workdir
VOLUME ["/workdir"]

ARG VNCPASSWD=zephyr
RUN mkdir ~/.vnc && x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd

