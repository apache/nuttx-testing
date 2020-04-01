#! /bin/sh

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
set -x

# This list should match the matrix in .github/workflows/build.yml
for l in arm-01 arm-02 arm-03 arm-04 arm-05 arm-06 arm-07 arm-08 arm-09 arm-10 arm-11 arm-12 arm-13 mips-riscv-x86-xtensa sim; do
    ./nuttx/tools/testbuild.sh -p ./testing/testlist/$l.dat
done \
| awk '/^Configuration\/Tool:/ {print $2}' | sort > combined.txt

./nuttx/tools/testbuild.sh -p ./testing/testlist/all.dat \
| awk '/^Configuration\/Tool:/ {print $2}' | sort > all.txt

diff -ud all.txt combined.txt
