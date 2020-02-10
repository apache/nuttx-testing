#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
set -e -x

WD=$(cd $(dirname $0) && pwd)
nuttx=$WD/../nuttx
apps=$WD/../apps
tools=$WD/../tools
prebuilt=$WD/../prebuilt

install="gen-romfs gperf kconfig-frontends arm-gcc-toolchain mips-gcc-toolchain riscv-gcc-toolchain c-cache"

function add_path {
  PATH=$1:$PATH
}

function gen-romfs {
  add_path $prebuilt/genromfs/usr/bin

  if [ ! -f "$prebuilt/genromfs/usr/bin/genromfs" ]; then
    if [ ! -d "$tools" ]; then
      git clone https://github.com/nuttx/tools.git $tools
    fi
    mkdir -p $prebuilt; cd $tools
    tar zxf genromfs-0.5.2.tar.gz -C $prebuilt
    cd $prebuilt/genromfs-0.5.2
    make install PREFIX=$prebuilt/genromfs
    cd $prebuilt
    rm -rf genromfs-0.5.2
  fi
}

function gperf {
  add_path $prebuilt/gperf/bin

  if [ ! -f "$prebuilt/gperf/bin/gperf" ]; then
    cd $prebuilt
    wget http://ftp.gnu.org/pub/gnu/gperf/gperf-3.1.tar.gz
    tar zxf gperf-3.1.tar.gz
    cd $prebuilt/gperf-3.1
    ./configure --prefix=$prebuilt/gperf; make; make install
    cd $prebuilt
    rm -rf gperf-3.1; rm gperf-3.1.tar.gz
  fi
}

function kconfig-frontends {
  add_path $prebuilt/kconfig-frontends/bin

  if [ ! -f "$prebuilt/kconfig-frontends/bin/kconfig-mconf" ]; then
    cd $tools/kconfig-frontends
    ./configure --prefix=$prebuilt/kconfig-frontends --enable-mconf --disable-gconf --disable-qconf --enable-static
    make install
    cd $tools; git clean -xfd
  fi
}

function arm-gcc-toolchain {
  add_path $prebuilt/gcc-arm-none-eabi/bin

  if [ ! -f "$prebuilt/gcc-arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
    cd $prebuilt
    wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
    tar jxf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
    mv gcc-arm-none-eabi-9-2019-q4-major gcc-arm-none-eabi
    rm gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
  fi
  arm-none-eabi-gcc --version
}

function mips-gcc-toolchain {
  add_path $prebuilt/pinguino-compilers/linux64/p32/bin

  if [ ! -f "$prebuilt/pinguino-compilers/linux64/p32/bin/p32-gcc" ]; then
    cd $prebuilt
    git clone https://github.com/PinguinoIDE/pinguino-compilers
  fi
  p32-gcc --version
}

function riscv-gcc-toolchain {
  add_path $prebuilt/riscv64-unknown-elf-gcc/bin

  if [ ! -f "$prebuilt/riscv64-unknown-elf-gcc/bin/riscv64-unknown-elf-gcc" ]; then
    cd $prebuilt
    wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz
    tar zxf riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz
    mv riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14 riscv64-unknown-elf-gcc
    rm riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-linux-ubuntu14.tar.gz
  fi
  riscv64-unknown-elf-gcc --version
}

function c-cache {
  add_path $prebuilt/ccache/bin

  if [ ! -f "$prebuilt/ccache/bin/ccache" ]; then
    cd $prebuilt;
    wget https://github.com/ccache/ccache/releases/download/v3.7.7/ccache-3.7.7.tar.gz
    tar zxf ccache-3.7.7.tar.gz
    cd ccache-3.7.7; ./configure --prefix=$prebuilt/ccache; make; make install
    cd $prebuilt; rm -rf ccache-3.7.7; rm ccache-3.7.7.tar.gz
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/gcc
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/g++
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/arm-none-eabi-gcc
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/arm-none-eabi-g++
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/p32-gcc
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/riscv64-unknown-elf-gcc
    ln -sf $prebuilt/ccache/bin/ccache $prebuilt/ccache/bin/riscv64-unknown-elf-g++
  fi
  ccache --version
}

function usage {
  echo ""
  echo "USAGE: $0 [-i] [-s] [-c] [-b <check|full>]"
  echo "       $0 -h"
  echo ""
  echo "Where:"
  echo "  -i install tools"
  echo "  -s setup repos"
  echo "  -c enable ccache"
  echo "  -b <check|full> do check or full CI Job"
  echo "  -h will show this help test and terminate"
  echo ""
  exit 1
}

function enable_ccache {
  export USE_CCACHE=1;
  export CCACHE_DIR=$prebuilt/ccache/.ccache;
  ccache -c
  ccache -M 5G;
  ccache -s
}

function setup_repos {
  if [ -d "$nuttx" ]; then
    cd $nuttx; git pull
  else
    git clone https://github.com/apache/incubator-nuttx.git $nuttx
  fi

  if [ -d "$apps" ]; then
    cd $apps; git pull
  else
    git clone https://github.com/apache/incubator-nuttx-apps.git $apps
  fi
}

function install_tools {
  for func in $install; do
    $func
  done
}

function run_builds {
  local ncpus=`grep -c ^processor /proc/cpuinfo`
  local options="-si -j $ncpus"

  if [ "X$build" = "Xcheck" ]; then
    options="$options -x"
  fi

  $nuttx/tools/testbuild.sh $options $WD/testlist/${build}list.dat
}

if [ -z "$1" ]; then
   usage
fi

while [ ! -z "$1" ]; do
  case "$1" in
  -h )
    usage
    ;;
  -i )
    install_tools
    ;;
  -c )
    enable_ccache
    ;;
  -b )
    shift
    build="$1"
    run_builds
    break
    ;;
  -s )
    setup_repos
    ;;
  * )
    usage
    ;;
  esac
  shift
done
