Dart Sync Socket
================

A Dart VM Native Extension and supporting Dart libraries that provide
synchronous socket and HTTP client support.

Installing
----------

Build the shared library:
```
cd <project_name>/lib/src
g++ -fPIC -I<path to SDK include directory> -c sync_socket_extension.cc
gcc -shared -Wl,-soname,libsync_socket_extension.so -o ../libsync_socket_extension.so sync_socket_extension.o
```

Testing
-------

TBD
