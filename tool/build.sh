#!/bin/bash

# Copyright 2015 Google Inc. All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

cd $(dirname $0)
SCRIPT_DIR=$(pwd)
DART_BIN=$(which dart)
DART_SDK_DIR=$(dirname $DART_BIN)/..
PLATFORM="$(uname -s)"
DART_VERSION=$(dart --version 2>&1)
case "$DART_VERSION" in
  (*32*)
    MACOS_ARCH="i386"
    LINUX_ARCH="32"
    ;;
  (*64*)
    MACOS_ARCH="x86_64"
    LINUX_ARCH="64"
    ;;
  (*)
    echo Unsupported dart architecture $DART_VERSION.  Exiting ... >&2
    exit 3
    ;;
esac

# see https://www.dartlang.org/articles/native-extensions-for-standalone-dart-vm/
cd $SCRIPT_DIR/..
pub install
cd lib/src
echo Building dart-sync-socket for platform $PLATFORM/$MACOS_ARCH
case "$PLATFORM" in
  (Darwin)
    g++ -fPIC -I $DART_SDK_DIR/include -c sync_socket_extension.cc -arch $MACOS_ARCH
    gcc -shared -Wl,-install_name,libsync_socket_extension.dylib,-undefined,dynamic_lookup,-arch,$DART_ARCH -o \
      ../libsync_socket_extension.dylib sync_socket_extension.o
    ;;
  (Linux)
    g++ -fPIC -I $DART_SDK_DIR/include -c sync_socket_extension.cc -m$LINUX_ARCH
    gcc -shared -Wl,-soname,libsync_socket_extension.so -o \
      ../libsync_socket_extension.so sync_socket_extension.o
    ;;
  (*)
    echo Unsupported platform $PLATFORM.  Exiting ... >&2
    exit 3
    ;;
esac