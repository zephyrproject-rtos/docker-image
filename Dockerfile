FROM ubuntu:20.04

ARG ZSDK_VERSION=0.14.1
ARG DOXYGEN_VERSION=1.9.4
ARG CMAKE_VERSION=3.20.5
ARG RENODE_VERSION=1.13.0
ARG LLVM_VERSION=12
ARG BSIM_VERSION=v1.0.3
ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll --no-check-certificate"

ARG UID=1000
ARG GID=1000

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
		software-properties-common \
		lsb-release \
		autoconf \
		automake \
		bison \
		build-essential \
		ca-certificates \
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
		gcovr \
		git \
		git-core \
		gnupg \
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
		xz-utils

# Install multi-lib gcc (x86 only)
RUN if [ "${HOSTTYPE}" = "x86_64" ]; then \
	apt-get install --no-install-recommends -y \
		gcc-multilib \
		g++-multilib \
	; fi

# Install i386 packages (x86 only)
RUN if [ "${HOSTTYPE}" = "x86_64" ]; then \
	dpkg --add-architecture i386 && \
	apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
		libsdl2-dev:i386 \
	; fi

# Initialise system locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Doxygen (x86 only)
# NOTE: Pre-built Doxygen binaries are only available for x86_64 host.
RUN if [ "${HOSTTYPE}" = "x86_64" ]; then \
	wget ${WGET_ARGS} https://downloads.sourceforge.net/project/doxygen/rel-${DOXYGEN_VERSION}/doxygen-${DOXYGEN_VERSION}.linux.bin.tar.gz && \
	tar xf doxygen-1.9.4.linux.bin.tar.gz -C /opt && \
	ln -s /opt/doxygen-1.9.4/bin/doxygen /usr/local/bin \
	; fi

# Install CMake
RUN wget ${WGET_ARGS} https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh && \
	chmod +x cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh && \
	./cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh --skip-license --prefix=/usr/local && \
	rm -f ./cmake-${CMAKE_VERSION}-Linux-${HOSTTYPE}.sh

# Install renode (x86 only)
# NOTE: Renode is currently only available for x86_64 host.
RUN if [ "${HOSTTYPE}" = "x86_64" ]; then \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
	apt-get -y update && \
	wget ${WGET_ARGS} https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb && \
	apt-get install -y ./renode_${RENODE_VERSION}_amd64.deb && \
	rm renode_${RENODE_VERSION}_amd64.deb \
	; fi

# Install Python dependencies
RUN pip3 install wheel pip -U &&\
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt && \
	pip3 install west &&\
	pip3 install sh &&\
	pip3 install awscli PyGithub junitparser pylint \
		     statistics numpy \
		     imgtool \
		     protobuf \
		     GitPython

# Install BSIM
RUN mkdir -p /opt/bsim && \
	cd /opt/bsim && \
	rm -f repo && \
	wget ${WGET_ARGS} https://storage.googleapis.com/git-repo-downloads/repo && \
	chmod a+x ./repo && \
	python3 ./repo init -u https://github.com/BabbleSim/manifest.git -m zephyr_docker.xml -b ${BSIM_VERSION} --depth 1 &&\
	python3 ./repo sync && \
	make everything -j 8 && \
	echo ${BSIM_VERSION} > ./version && \
	chmod ag+w . -R

# Install uefi-run utility
RUN wget ${WGET_ARGS} https://static.rust-lang.org/rustup/rustup-init.sh && \
	chmod +x rustup-init.sh && \
	./rustup-init.sh -y && \
	. $HOME/.cargo/env && \
	cargo install uefi-run --root /usr && \
	rm -f ./rustup-init.sh

# Install LLVM and Clang
RUN wget ${WGET_ARGS} -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
	apt-get update && \
	apt-get install -y clang-$LLVM_VERSION lldb-$LLVM_VERSION lld-$LLVM_VERSION clangd-$LLVM_VERSION llvm-$LLVM_VERSION-dev

# Install Zephyr SDK
RUN mkdir -p /opt/toolchains && \
	cd /opt/toolchains && \
	wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
	tar xf zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz && \
	zephyr-sdk-${ZSDK_VERSION}/setup.sh -t all -h -c && \
	rm zephyr-sdk-${ZSDK_VERSION}_linux-${HOSTTYPE}.tar.gz

# Clean up stale packages
RUN apt-get clean -y && \
	apt-get autoremove --purge -y && \
	rm -rf /var/lib/apt/lists/*

# Create 'user' account
RUN groupadd -g $GID -o user

RUN useradd -u $UID -m -g user -G plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user

# Run the Zephyr SDK setup script as 'user' in order to ensure that the
# `Zephyr-sdk` CMake package is located in the package registry under the
# user's home directory.
USER user

RUN sudo -E -- bash -c ' \
	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/setup.sh -c && \
	chown -R user:user /home/user/.cmake \
	'

USER root

# Set the locale
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV OVMF_FD_PATH=/usr/share/ovmf/OVMF.fd
