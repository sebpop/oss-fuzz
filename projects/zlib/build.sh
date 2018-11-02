#!/bin/bash -eu

./configure
make -j$(nproc) clean
make -j$(nproc) all

# Do not make check as there are tests that fail when compiled with MSAN.
# make -j$(nproc) check

zip $OUT/seed_corpus.zip *.*

for f in $(find $SRC -name '*_fuzzer.c'); do
    b=$(basename -s .c $f)
    $CXX $CXXFLAGS -std=c++11 -I. $f -o $OUT/$b -lFuzzingEngine ./libz.a
    ln -s $OUT/seed_corpus.zip $OUT/${b}_seed_corpus.zip
done
