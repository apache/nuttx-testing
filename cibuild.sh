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

set -e

WD=$(cd $(dirname $0) && pwd)
nuttx=$WD/../nuttx
apps=$WD/../apps
tools=$WD/../tools
prebuilt=$WD/../prebuilt
os=$(uname -s)

case $os in
  Darwin)
    install="python-tools u-boot-tools discoteq-flock elf-toolchain gen-romfs kconfig-frontends arm-gcc-toolchain riscv-gcc-toolchain xtensa-esp32-gcc-toolchain"
    mkdir -p ${prebuilt}/homebrew
    export HOMEBREW_CACHE=${prebuilt}/homebrew
    ;;
  Linux)
    install="python-tools gen-romfs gperf kconfig-frontends arm-gcc-toolchain mips-gcc-toolchain riscv-gcc-toolchain xtensa-esp32-gcc-toolchain c-cache"
    ;;
esac

function add_path {
  PATH=$1:$PATH
}

function python-tools {
  # Python User Env
  PIP_USER=yes
  PYTHONUSERBASE=$prebuilt/pylocal
  add_path $PYTHONUSERBASE/bin
}

function u-boot-tools {
  if ! type mkimage > /dev/null; then
    case $os in
      Darwin)
        brew install u-boot-tools
        ;;
    esac
  fi
}

function discoteq-flock {
  if ! type flock > /dev/null; then
    case $os in
      Darwin)
        brew tap discoteq/discoteq
        brew install flock
        ;;
    esac
  fi
}

function elf-toolchain {
  if ! type x86_64-elf-gcc > /dev/null; then
    case $os in
      Darwin)
        brew install x86_64-elf-gcc
        ;;
    esac
  fi
  x86_64-elf-gcc --version
}

function gen-romfs {
  add_path $prebuilt/genromfs/usr/bin

  if [ ! -f "$prebuilt/genromfs/usr/bin/genromfs" ]; then
    if [ ! -d "$tools" ]; then
      git clone https://bitbucket.org/nuttx/tools.git $tools
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

  if [ ! -f "$prebuilt/kconfig-frontends/bin/kconfig-conf" ]; then
    cd $tools/kconfig-frontends
    ./configure --prefix=$prebuilt/kconfig-frontends \
      --disable-kconfig --disable-nconf --disable-qconf \
      --disable-gconf --disable-mconf --disable-static \
      --disable-shared --disable-L10n
    # Avoid "aclocal/automake missing" errors
    touch aclocal.m4 Makefile.in
    make install
    cd $tools; git clean -xfd
  fi
}

function arm-gcc-toolchain {
  add_path $prebuilt/gcc-arm-none-eabi/bin

  if [ ! -f "$prebuilt/gcc-arm-none-eabi/bin/arm-none-eabi-gcc" ]; then
    local flavor
    case $os in
      Darwin)
        flavor=mac
        ;;
      Linux)
        flavor=x86_64-linux
        ;;
    esac
    cd $prebuilt
    wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/RC2.1/gcc-arm-none-eabi-9-2019-q4-major-${flavor}.tar.bz2
    tar jxf gcc-arm-none-eabi-9-2019-q4-major-${flavor}.tar.bz2
    mv gcc-arm-none-eabi-9-2019-q4-major gcc-arm-none-eabi
    rm gcc-arm-none-eabi-9-2019-q4-major-${flavor}.tar.bz2
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
    local flavor
    case $os in
      Darwin)
        flavor=x86_64-apple-darwin
        ;;
      Linux)
        flavor=x86_64-linux-ubuntu14
        ;;
    esac
    cd $prebuilt
    wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-${flavor}.tar.gz
    tar zxf riscv64-unknown-elf-gcc-8.3.0-2019.08.0-${flavor}.tar.gz
    mv riscv64-unknown-elf-gcc-8.3.0-2019.08.0-${flavor} riscv64-unknown-elf-gcc
    rm riscv64-unknown-elf-gcc-8.3.0-2019.08.0-${flavor}.tar.gz
  fi
  riscv64-unknown-elf-gcc --version
}

function xtensa-esp32-gcc-toolchain {
  add_path $prebuilt/xtensa-esp32-elf/bin

  if [ ! -f "$prebuilt/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc" ]; then
    cd $prebuilt
    case $os in
      Darwin)
        wget https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_2_0-esp-2019r2-macos.tar.gz
        tar xzf xtensa-esp32-elf-gcc8_2_0-esp-2019r2-macos.tar.gz
        rm xtensa-esp32-elf-gcc8_2_0-esp-2019r2-macos.tar.gz
        ;;
      Linux)
        wget https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_2_0-esp32-2019r1-rc2-linux-amd64.tar.xz
        xz -d xtensa-esp32-elf-gcc8_2_0-esp32-2019r1-rc2-linux-amd64.tar.xz
        tar xf xtensa-esp32-elf-gcc8_2_0-esp32-2019r1-rc2-linux-amd64.tar
        rm xtensa-esp32-elf-gcc8_2_0-esp32-2019r1-rc2-linux-amd64.tar
        ;;
    esac
  fi
  xtensa-esp32-elf-gcc --version
  pip install esptool
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
  echo "USAGE: $0 [-i] [-s] [-c] [-*] <testlist>"
  echo "       $0 -h"
  echo ""
  echo "Where:"
  echo "  -i install tools"
  echo "  -s setup repos"
  echo "  -c enable ccache"
  echo "  -* support all options in testbuild.sh"
  echo "  -h will show this help test and terminate"
  echo "  <testlist> select testlist file"
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
  pushd .
  if [ -d "$nuttx" ]; then
    cd $nuttx; git pull
  else
    git clone https://github.com/apache/incubator-nuttx.git $nuttx
    cd $nuttx
  fi
  git log -1

  if [ -d "$apps" ]; then
    cd $apps; git pull
  else
    git clone https://github.com/apache/incubator-nuttx-apps.git $apps
    cd $apps
  fi
  git log -1
  popd
}

function install_tools {
  pushd .
  for func in $install; do
    $func
  done
  popd
}

function run_builds {
  local ncpus

  case $os in
    Darwin)
      ncpus=$(sysctl -n machdep.cpu.thread_count)
      ;;
    Linux)
      ncpus=`grep -c ^processor /proc/cpuinfo`
      ;;
  esac

  options+="-j $ncpus"

  for build in $builds; do
    $nuttx/tools/testbuild.sh $options -e "-Wno-cpp -Werror" $build
  done
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
  -s )
    setup_repos
    ;;
  -* )
    options+="$1 "
    ;;
  * )
    builds=$@
    break
    ;;
  esac
  shift
done

run_builds
