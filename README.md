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

Build the DLL (Windows 32 bits):
  - Create a new project of type Win32/Win32 project in Visual Studio 2010 Express.
  - Give the project the name sync_socket.
  - On the next screen of the wizard, change the application type to DLL and select “Empty project”, then choose Finish.
  - Add the "sync_socket_extension.cc" file to the source files folder in the project.
  - Change the following settings in the project’s properties:
     - Configuration properties / Linker / Enable Incremental Linking: Set to NO.
     - Configuration properties / Linker / Input / Additional dependencies: Add dart-sdk\bin\dart.lib, from the downloaded Dart SDK.
     - Configuration properties / Linker / Input / Additional dependencies: Add Ws2_32.lib.lib. This is the Winsock library.
     - Configuration properties / C/C++ / General / Additional Include Directories: Add the path to the directory containing dart_api.h, which is dart-sdk/include in the downloaded Dart SDK.
     - Configuration properties / C/C++ / Preprocessor / Preprocessor Definitions: Add DART_SHARED_LIB. This is just to export the _init function from the DLL, since it has been declared as DART_EXPORT.
  - Build the project with "Release" target, and copy the DLL to the directory "lib".

The library has not been tested on other platforms, but should work. To build
for Windows (64 bits) or Mac OS X look at the instructions at
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
