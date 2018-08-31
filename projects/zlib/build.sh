#!/bin/bash -eu

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
    ln -s $OUT/seed_corpus.zip $OUT/${f}_seed_corpus.zip
done
