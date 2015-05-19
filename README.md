Dart Sync Socket
================

[![Build Status](https://travis-ci.org/google/dart-sync-socket.svg?branch=master)](https://travis-ci.org/google/dart-sync-socket)
[![pub package](https://img.shields.io/pub/v/sync_socket.svg)](https://pub.dartlang.org/packages/sync_socket)

A Dart VM Native Extension and supporting Dart libraries that provide
synchronous socket and HTTP client support.

Installing
----------

Add the following to your pubspec.yaml:
```YAML
  sync_socket: '^1.0.1'
```

Then run 'pub get'.

After getting the package with pub, you will need to build the native extension itself.

To build the shared library on Mac OSX or Linux, run the 'tool/build.sh' script.

To build the DLL on Windows (32 bits):
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

Testing
-------

Follow the instructions above for building the shared library then run tests
as normal.
