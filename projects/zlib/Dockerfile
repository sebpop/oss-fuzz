# Copyright 2016 Google Inc.
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

FROM gcr.io/oss-fuzz-base/base-builder
MAINTAINER sebpop@gmail.com
RUN apt-get update && apt-get install -y make autoconf automake libtool

# The code of the fuzzers was not accepted upstream.
# First clone from a repo that contains the code of the fuzzers.
RUN git clone -b fuzz https://github.com/sebpop/zlib.git

# Then pull rebase the last patches from upstream.
RUN git pull -r https://github.com/madler/zlib.git develop

WORKDIR zlib
COPY build.sh $SRC/
