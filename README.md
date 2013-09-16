Dart Sync Socket
================

A Dart VM Native Extension and supporting Dart libraries that provide
synchronous socket and HTTP client support.

Installing
----------

Note: http://pub.dartlang.org doesn't currently suport publishing native
extensions, so this library is not available there. To use, download the latest
release from the releases page and extract locally.

Build the shared library (Linux):
```
cd <project_name>/lib/src
g++ -fPIC -I<path to SDK include directory> -c sync_socket_extension.cc
gcc -shared -Wl,-soname,libsync_socket_extension.so -o \
    ../libsync_socket_extension.so sync_socket_extension.o
```

The library has not been tested on other platforms, but should work. To build
for Windows or Mac OS X look at the instructions at
https://www.dartlang.org/articles/native-extensions-for-standalone-dart-vm/


Add the following to your pubspec.yaml:
```
  sync_socket:
    path: <path to sync_socket>
```

Testing
-------

Follow the instructions above for building the shared library then run tests
as normal.
