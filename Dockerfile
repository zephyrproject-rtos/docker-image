FROM ubuntu:20.04

ARG ZSDK_VERSION=0.13.1
ARG GCC_ARM_NAME=gcc-arm-none-eabi-10-2020-q4-major
ARG CMAKE_VERSION=3.20.5
ARG RENODE_VERSION=1.12.0
ARG LLVM_VERSION=12
ARG BSIM_VERSION=v1.0.3
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
	gnupg \
	ca-certificates && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
	apt-get -y update && \
	apt-get install --no-install-recommends -y \
	software-properties-common \
	lsb-release \
	autoconf \
	automake \
	bison \
	build-essential \
	ccache \
	chrpath \
	cpio \
	device-tree-compiler \
	dfu-util \
	diffstat \
	dos2unix \
	doxygen \
	file \
	flex \
	g++ \
	gawk \
	gcc \
	gcc-multilib \
	g++-multilib \
	gcovr \
	git \
	git-core \
	gperf \
	gtk-sharp2 \
	help2man \
	iproute2 \
	lcov \
	libglib2.0-dev \
	libgtk2.0-0 \
	liblocale-gettext-perl \
	libncurses5-dev \
	libpcap-dev \
	libpopt0 \
	libsdl2-dev:i386 \
	libsdl1.2-dev \
	libsdl2-dev \
	libssl-dev \
	libtool \
	libtool-bin \
	locales \
	make \
	net-tools \
	ninja-build \
	openssh-client \
	pkg-config \
	protobuf-compiler \
	python3-dev \
	python3-pip \
	python3-ply \
	python3-setuptools \
	python-is-python3 \
	qemu \
	rsync \
	socat \
	srecord \
	sudo \
	texinfo \
	unzip \
	valgrind \
	wget \
	ovmf \
	xz-utils && \
	wget ${WGET_ARGS} https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb && \
	apt install -y ./renode_${RENODE_VERSION}_amd64.deb && \
	rm renode_${RENODE_VERSION}_amd64.deb && \
	rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN pip3 install wheel pip -U &&\
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt && \
	pip3 install west &&\
	pip3 install sh &&\
	pip3 install awscli PyGithub junitparser pylint \
		     statistics numpy \
		     imgtool \
		     protobuf


RUN mkdir -p /opt/toolchains

RUN wget ${WGET_ARGS} https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/${GCC_ARM_NAME}-x86_64-linux.tar.bz2  && \
	tar -xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 -C /opt/toolchains/ && \
	rm -f ${GCC_ARM_NAME}-x86_64-linux.tar.bz2

RUN wget ${WGET_ARGS} https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
	rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

RUN wget ${WGET_ARGS} -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	apt-get update && \
	apt-get install -y clang-$LLVM_VERSION lldb-$LLVM_VERSION lld-$LLVM_VERSION clangd-$LLVM_VERSION llvm-$LLVM_VERSION-dev

RUN mkdir -p /opt/bsim
RUN cd /opt/bsim && \
	rm -f repo && \
	wget ${WGET_ARGS} https://storage.googleapis.com/git-repo-downloads/repo && \
	chmod a+x ./repo && \
	python3 ./repo init -u https://github.com/BabbleSim/manifest.git -m zephyr_docker.xml -b ${BSIM_VERSION} --depth 1 &&\
	python3 ./repo sync && \
	make everything -j 8 && \
	echo ${BSIM_VERSION} > ./version && \
	chmod ag+w . -R

RUN apt-get clean && \
	sudo apt-get autoremove --purge

RUN groupadd -g $GID -o user

RUN useradd -u $UID -m -g user -G plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user

RUN wget ${WGET_ARGS} https://static.rust-lang.org/rustup/rustup-init.sh && \
	chmod +x rustup-init.sh && \
	./rustup-init.sh -y && \
	. $HOME/.cargo/env && \
	cargo install uefi-run --root /usr && \
	rm -f ./rustup-init.sh

# Install Zephyr SDK as 'user' in order to ensure that the `Zephyr-sdk` CMake
# package is located in the package registry under the user's home directory.
USER user

RUN sudo -E -- sh -c ' \
	wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run && \
	sh "zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} -y -norc && \
	rm "zephyr-sdk-${ZSDK_VERSION}-linux-x86_64-setup.run" \
	'

USER root

# Set the locale
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV OVMF_FD_PATH=/usr/share/ovmf/OVMF.fd
