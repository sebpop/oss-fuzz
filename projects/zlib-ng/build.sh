#!/bin/bash -eu
# Copyright 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

export LDSHARED=$CXX
export LDFLAGS="$CFLAGS -stdlib=libc++"
./configure
sed -i "/^LDSHARED=.*/s#=.*#=$CXX#" Makefile
sed -i 's/$(CC) $(LDFLAGS)/$(CXX) $(LDFLAGS)/g' Makefile

make -j$(nproc) clean
make -j$(nproc) all
make -j$(nproc) check

zip $OUT/seed_corpus.zip *.*

for f in $(find . -name '*_fuzzer'); do
    cp -v $f $OUT
    (cd $OUT; ln -s seed_corpus.zip $(basename $f)_seed_corpus.zip)
done


# Cross compiling libfuzzer may be moved to compile_libfuzzer: ------
echo -n "AArch64 cross compiling libFuzzer to $LIB_FUZZING_ENGINE.aarch64.a... "
mkdir -p $WORK/libfuzzer
pushd $WORK/libfuzzer > /dev/null
aarch64-libcxx-clang++ $CXXFLAGS -std=c++11 -O2 $SANITIZER_FLAGS -fno-sanitize=vptr \
    -c $SRC/libfuzzer/*.cpp -I$SRC/libfuzzer
/usr/bin/aarch64-linux-gnu-ar r $LIB_FUZZING_ENGINE.aarch64.a $WORK/libfuzzer/*.o > /dev/null
popd > /dev/null
rm -rf $WORK/libfuzzer
echo " done."
# ---------------------

# AArch64 cross compile.
save_LIB_FUZZING_ENGINE=$LIB_FUZZING_ENGINE
LIB_FUZZING_ENGINE=$LIB_FUZZING_ENGINE.aarch64.a
save_CXX=$CXX
save_CC=$CC
save_CFLAGS=$CFLAGS
save_CXXFLAGS=$CXXFLAGS

export CXX=aarch64-libcxx-clang++
export CC=aarch64-clang
export LDSHARED=$CXX
# MSan needs to be compiled with -fPIE -pie.
export CFLAGS="$CFLAGS -fPIE"
export LDFLAGS="$CFLAGS -pie"
./configure
sed -i "/^LDSHARED=.*/s#=.*#=$CXX#" Makefile
sed -i 's/$(CC) $(LDFLAGS)/$(CXX) $(LDFLAGS)/g' Makefile

make -j$(nproc) clean
make -j$(nproc) all

mkdir -p $OUT/aarch64
for f in $(find . -name '*_fuzzer'); do
    # zip the aarch64 executables in order to avoid calling ldd on them.
    zip $OUT/aarch64/$f.zip $f
    echo "#!/bin/bash" > $OUT/$f.sh
    echo "unzip $OUT/aarch64/$f.zip -d $OUT/aarch64" >> $OUT/$f.sh
    echo "qemu-aarch64 -L /usr/aarch64-linux-gnu $OUT/aarch64/$f" >> $OUT/$f.sh
    echo "rm -f $OUT/aarch64/$f" >> $OUT/$f.sh
    chmod +x $OUT/$f.sh
    (cd $OUT; ln -s seed_corpus.zip $f.sh_seed_corpus.zip)
done

apt install -y qemu-user libc6-arm64-cross libgcc1-arm64-cross

export LIB_FUZZING_ENGINE=$save_LIB_FUZZING_ENGINE
export CXX=$save_CXX
export CC=$save_CC
export CFLAGS=$save_CFLAGS
export CXXFLAGS=$save_CXXFLAGS
