#!/bin/bash

PLATFORMS=""
PLATFORMS="$PLATFORMS darwin/amd64"              # amd64 only as of go1.5
PLATFORMS="$PLATFORMS windows/amd64 windows/386" # arm compilation not available for Windows
PLATFORMS="$PLATFORMS linux/amd64 linux/386"
# PLATFORMS="$PLATFORMS linux/ppc64 linux/ppc64le"
PLATFORMS="$PLATFORMS linux/mips linux/mipsle linux/mips64 linux/mips64le" # experimental in go1.6
#PLATFORMS="$PLATFORMS linux/arm linux/arm64"
PLATFORMS="$PLATFORMS freebsd/amd64"
# PLATFORMS="$PLATFORMS netbsd/amd64" # amd64 only as of go1.6
# PLATFORMS="$PLATFORMS openbsd/amd64" # amd64 only as of go1.6
# PLATFORMS="$PLATFORMS dragonfly/amd64" # amd64 only as of go1.5
# PLATFORMS="$PLATFORMS plan9/amd64 plan9/386" # as of go1.4
# PLATFORMS="$PLATFORMS solaris/amd64" # as of go1.3

PLATFORMS_ARM="linux"

##############################################################
# Shouldn't really need to modify anything below this line.  #
##############################################################

type setopt >/dev/null 2>&1

export GOPATH="${PWD}"
GOBIN="/usr/local/go/bin/go"

[ -d src/github.com/alexflint/go-arg ] && go get -v github.com/alexflint/go-arg

[ -d src/github.com/anacrolix/dht ] && go get -v github.com/anacrolix/dht
[ -d src/github.com/anacrolix/missinggo/httptoo ] && go get -v github.com/anacrolix/missinggo/httptoo
[ -d src/github.com/anacrolix/torrent ] && go get -v github.com/anacrolix/torrent
[ -d src/github.com/anacrolix/torrent/iplist ] && go get -v github.com/anacrolix/torrent/iplist
[ -d src/github.com/anacrolix/torrent/metainfo ] && go get -v github.com/anacrolix/torrent/metainfo
[ -d src/github.com/anacrolix/utp ] && go get -v github.com/anacrolix/utp

[ -d src/github.com/gin-gonic/gin ] && go get -u github.com/gin-gonic/gin

[ -d src/github.com/pion/webrtc/v2 ] && go get -v github.com/pion/webrtc/v2
[ -d src/go.etcd.io/bbolt ] && go get -v go.etcd.io/bbolt

ln -s . src/github.com/pion/webrtc/v2

$GOBIN version

SCRIPT_NAME=$(basename "$0")
FAILURES=""
SOURCE_FILE="dist/TorrServer"
CURRENT_DIRECTORY=${PWD##*/}
OUTPUT=${SOURCE_FILE:-$CURRENT_DIRECTORY} # if no src file given, use current dir name

for PLATFORM in $PLATFORMS; do
  GOOS=${PLATFORM%/*}
  GOARCH=${PLATFORM#*/}
  BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}"
  if [[ "${GOOS}" == "windows" ]]; then BIN_FILENAME="${BIN_FILENAME}.exe"; fi
  if [[ "${GOOS}" == "linux" ]]; then
    CMD="CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} ${GOBIN} build -o ${BIN_FILENAME} main"
  else
    CMD="GOOS=${GOOS} GOARCH=${GOARCH} ${GOBIN} build -o ${BIN_FILENAME} main"
  fi
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
done

# ARM builds
if [[ $PLATFORMS_ARM == *"linux"* ]]; then
  CMD="GOOS=linux GOARCH=arm64 ${GOBIN} build -o ${OUTPUT}-linux-arm64 main"
  echo "${CMD}"
  eval $CMD || FAILURES="${FAILURES} ${PLATFORM}"
fi

for GOOS in $PLATFORMS_ARM; do
  GOARCH="arm"
  # build for each ARM version
  for GOARM in 7 6 5; do
    BIN_FILENAME="${OUTPUT}-${GOOS}-${GOARCH}${GOARM}"
    CMD="GOARM=${GOARM} GOOS=${GOOS} GOARCH=${GOARCH} ${GOBIN} build -o ${BIN_FILENAME} main"
    echo "${CMD}"
    eval "${CMD}" || FAILURES="${FAILURES} ${GOOS}/${GOARCH}${GOARM}"
  done
done

# eval errors
if [[ "${FAILURES}" != "" ]]; then
  echo ""
  echo "${SCRIPT_NAME} failed on: ${FAILURES}"
  exit 1
fi

export CGO_ENABLED=1
export GOOS=android
export LDFLAGS="-s -w"

# GOBIN="/usr/local/go_111/bin/go"

$GOBIN version

export NDK_TOOLCHAIN=$GOPATH/toolchains
export CC=$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi21-clang
export CXX=$NDK_TOOLCHAIN/bin/armv7a-linux-androideabi21-clang++
export GOARCH=arm
export GOARM=7
BIN_FILENAME="dist/TorrServer-${GOOS}-${GOARCH}${GOARM}"
echo "Android ${BIN_FILENAME}"
${GOBIN} build -ldflags="${LDFLAGS}" -o ${BIN_FILENAME} main

export CC=$NDK_TOOLCHAIN/bin/aarch64-linux-android21-clang
export CXX=$NDK_TOOLCHAIN/bin/aarch64-linux-android21-clang++
export GOARCH=arm64
export GOARM=""
BIN_FILENAME="dist/TorrServer-${GOOS}-${GOARCH}${GOARM}"
echo "Android ${BIN_FILENAME}"
${GOBIN} build -ldflags="${LDFLAGS}" -o ${BIN_FILENAME} main

export CC=$NDK_TOOLCHAIN/bin/i686-linux-android21-clang
export CXX=$NDK_TOOLCHAIN/bin/i686-linux-android21-clang++
export GOARCH=386
export GOARM=""
BIN_FILENAME="dist/TorrServer-${GOOS}-${GOARCH}${GOARM}"
echo "Android ${BIN_FILENAME}"
${GOBIN} build -ldflags="${LDFLAGS}" -o ${BIN_FILENAME} main

export CC=$NDK_TOOLCHAIN/bin/x86_64-linux-android21-clang
export CXX=$NDK_TOOLCHAIN/bin/x86_64-linux-android21-clang++
export GOARCH=amd64
export GOARM=""
BIN_FILENAME="dist/TorrServer-${GOOS}-${GOARCH}${GOARM}"
echo "Android ${BIN_FILENAME}"
${GOBIN} build -ldflags="${LDFLAGS}" -o ${BIN_FILENAME} main

# ./compile.sh
