# Really simple docker image to give you an environment with the Ci20 build stuff.
# Also serves as a guide on what commands you need to run to grab a toolchain
# compile a kernel etc.

# If you don't know how to use docker.
# Install docker, clone this repo, cd into the folder, then run
# docker build ci20 .
# docker run -i -t ci20 # this is for first entry. if you want to subsequently enter your previous docker
# do 'docker ps -a', check what funny name it got and then 'docker run -i -t some_name'
# you'll be inside a ubuntu docker with toolchain/kernel/sgx_km/u-boot
# user: build root pass: build

# Actual Dockerfile from here.
# Use ubuntu 14.04 as a base image
FROM ubuntu:14.04

# Update repos. Install packages required to build the kernel
RUN apt-get update
RUN apt-get install -q -y build-essential git wget libc6-i386 bc u-boot-tools

# Add build user
RUN useradd -ms /bin/bash build && echo "build:build" | chpasswd && adduser build sudo

# Switch to build user
USER build

# Working directory. This is like using cd to enter a directory. e.g '$>cd /home/build'
WORKDIR /home/build/

# Get toolchain
RUN mkdir /home/build/toolchain
RUN wget https://sourcery.mentor.com/GNUToolchain/package12215/public/mips-linux-gnu/mips-2013.11-36-mips-linux-gnu-i686-pc-linux-gnu.tar.bz2
RUN tar -xf mips-2013.11-36-mips-linux-gnu-i686-pc-linux-gnu.tar.bz2 -C /home/build/toolchain

# Get kernel source
RUN git clone https://github.com/MIPS/CI20_linux.git linux

# Get u-boot source
RUN git clone https://github.com/MIPS/CI20_u-boot.git u-boot

# Get SGX kernel module source
RUN mkdir /home/build/sgx_km
RUN wget http://mipscreator.imgtec.com/CI20/sgx/SGX_DDK_Linux_XOrg_MAIN%403759903_source_km.tgz
RUN tar -xf SGX_DDK_Linux_XOrg_* -C /home/build/sgx_km

# Compile the Linux Kernel
WORKDIR /home/build/linux
RUN make ARCH=mips ci20_defconfig
RUN CROSS_COMPILE=/home/build/toolchain/mips-2013.11/bin/mips-linux-gnu- ARCH=mips make -j4 uImage

# Compile the SGX Kernel Module
WORKDIR /home/build/sgx_km/eurasia_km
RUN CROSS_COMPILE=/home/build/toolchain/mips-2013.11/bin/mips-linux-gnu- ARCH=mips KERNELDIR=/home/build/linux make -C eurasiacon/build/linux2/jz4780_linux

# Compile u-boot
WORKDIR /home/build/u-boot
RUN git checkout ci20-v2013.10
# u-boot defconfigs for NAND and MMC are different. Be careful. 
# For NAND
RUN make ARCH=mips CROSS_COMPILE=/home/build/toolchain/mips-2013.11/bin/mips-linux-gnu- ci20
# For MMC
RUN make ARCH=mips CROSS_COMPILE=/home/build/toolchain/mips-2013.11/bin/mips-linux-gnu- ci20_mmc

# default to a terminal. This is so running 'docker run -i -t ci20' results in bash running.
CMD ["/bin/bash"]
