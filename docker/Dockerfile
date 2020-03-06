FROM ubuntu:18.04
MAINTAINER Haitao Liu<liuguo09@gmail.com>

RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y git-core automake bison build-essential flex gperf wget libx11-dev libxext-dev u-boot-tools
RUN apt-get install -y lib32z1-dev lib32ncurses5-dev libc6-dev-i386 libx11-dev:i386 libxext-dev:i386
RUN apt-get install -y curl gettext
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y xxd
RUN apt-get install -y unzip
RUN apt-get clean
RUN mkdir /prebuilt

WORKDIR /prebuilt

ADD gcc-arm-none-eabi.tar.gz ./
ADD pinguino-compilers.tar.gz ./
ADD riscv64-unknown-elf-gcc.tar.gz ./
ADD genromfs-0.5.2.tar.gz ./
ADD kconfig-frontends-4.11.0.tar.gz ./
ADD git-2.18.0.tar.gz ./

RUN cd /prebuilt/genromfs-0.5.2 && make install PREFIX=/prebuilt/genromfs

RUN cd /prebuilt/kconfig-frontends-4.11.0 && ./configure --prefix=/prebuilt/kconfig-frontends --enable-mconf --disable-gconf --disable-qconf --enable-static && make install

RUN cd /prebuilt/git-2.18.0 && ./configure --prefix=/prebuilt/git && make install

RUN rm -rf /prebuilt/genromfs-0.5.2 /prebuilt/kconfig-frontends-4.11.0 /prebuilt/git-2.18.0

ENV PATH /prebuilt/git/bin:/prebuilt/genromfs/usr/bin:/prebuilt/kconfig-frontends/bin:/prebuilt/gcc-arm-none-eabi/bin:/prebuilt/pinguino-compilers/linux64/p32/bin:/prebuilt/riscv64-unknown-elf-gcc/bin:$PATH

CMD [ "/bin/bash" ]
