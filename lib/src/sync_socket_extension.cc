// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <sys/types.h>
#ifdef WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <wspiapi.h>
#include <io.h>
#pragma comment(lib, "Ws2_32.lib")
#define write(fd, buf, len) send(fd, buf, len, 0)
#define read(fd, buf, len) recv(fd, (char*)buf, len, 0)
#define close closesocket
#else
#include <sys/socket.h>
#include <netdb.h>
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dart_api.h"

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool* auto_setup_scope);
Dart_Handle NewDartExceptionWithMessage(const char* library_url,
                                        const char* exception_name,
                                        const char* message);

DART_EXPORT Dart_Handle sync_socket_extension_Init(Dart_Handle parent_library) {
  if (Dart_IsError(parent_library)) return parent_library;

  Dart_Handle result_code =
      Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) return result_code;

  return Dart_Null();
}

void sync_connect(Dart_NativeArguments args) {
  const char *hostname, *port;  // args[0] args[1]
  int sockfd;                   // return

  struct addrinfo *addrs, *ap;
  struct addrinfo hints;
  Dart_Handle handle;

  handle = Dart_StringToCString(Dart_GetNativeArgument(args, 0), &hostname);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  handle = Dart_StringToCString(Dart_GetNativeArgument(args, 1), &port);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = 0;
  hints.ai_protocol = 0;

  if (getaddrinfo(hostname, port, &hints, &addrs) != 0) {
    Dart_Handle error = NewDartExceptionWithMessage(
        "dart:io", "SocketException", "Unable to resolve host");
    if (Dart_IsError(error)) Dart_PropagateError(error);
    Dart_ThrowException(error);
  }
  for (ap = addrs; ap != NULL; ap = ap->ai_next) {
    sockfd = socket(ap->ai_family, ap->ai_socktype, ap->ai_protocol);

#ifdef WIN32
    if (sockfd == INVALID_SOCKET) {
#else
    if (sockfd < 0) {
#endif
      continue;
    }
    if (connect(sockfd, ap->ai_addr, ap->ai_addrlen) != -1) {
      break;
    }
    close(sockfd);
#ifdef WIN32
    sockfd = INVALID_SOCKET;
#else
    sockfd = -1;
#endif
  }

  freeaddrinfo(addrs);

#ifdef WIN32
  if (sockfd == INVALID_SOCKET) {
#else
  if (sockfd < 0) {
#endif
    Dart_Handle error = NewDartExceptionWithMessage(
        "dart:io", "SocketException", "Unable to connect to host");
    if (Dart_IsError(error)) Dart_PropagateError(error);
    Dart_ThrowException(error);
  }

  Dart_Handle retval = Dart_NewInteger((int64_t)sockfd);

  if (Dart_IsError(retval)) Dart_PropagateError(retval);

  Dart_SetReturnValue(args, retval);
}

void sync_close(Dart_NativeArguments args) {
  int64_t sockfd;  // args[0]
  Dart_Handle handle;

  handle = Dart_IntegerToInt64(Dart_GetNativeArgument(args, 0), &sockfd);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  close(static_cast<int>(sockfd));
}

void freeData(void* isolate_callback_data, Dart_WeakPersistentHandle handle,
              void* buffer) {
  free(buffer);
}

void sync_read(Dart_NativeArguments args) {
  int64_t sockfd;   // args[0]
  uint64_t length;  // args[1]
  uint8_t *buffer, *data;
  int bytes_read;

  Dart_Handle handle;

  handle = Dart_IntegerToInt64(Dart_GetNativeArgument(args, 0), &sockfd);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  handle = Dart_IntegerToUint64(Dart_GetNativeArgument(args, 1), &length);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  buffer = reinterpret_cast<uint8_t*>(malloc(length * sizeof(uint8_t)));

  bytes_read = read(static_cast<int>(sockfd), buffer, static_cast<int>(length));

  if (bytes_read < 0) {
    free(buffer);
    Dart_Handle error = NewDartExceptionWithMessage(
        "dart:io", "SocketException", "Error reading from socket");
    if (Dart_IsError(error)) Dart_PropagateError(error);
    Dart_ThrowException(error);
  }

  data = reinterpret_cast<uint8_t*>(malloc(bytes_read * sizeof(uint8_t)));
  memcpy(data, buffer, bytes_read);
  free(buffer);

  Dart_Handle result =
      Dart_NewExternalTypedData(Dart_TypedData_kUint8, data, bytes_read);
  if (Dart_IsError(result)) Dart_PropagateError(result);

  Dart_NewWeakPersistentHandle(result, data, bytes_read, freeData);

  Dart_SetReturnValue(args, result);
}

void sync_write(Dart_NativeArguments args) {
  int64_t sockfd;  // args[0]
  char* bytes;
  intptr_t length;
  int64_t byte;
  Dart_Handle list;
  int i;

  Dart_Handle handle;

  handle = Dart_IntegerToInt64(Dart_GetNativeArgument(args, 0), &sockfd);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  list = Dart_GetNativeArgument(args, 1);
  handle = Dart_ListLength(list, &length);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  bytes = reinterpret_cast<char*>(malloc(length * sizeof(char)));

  for (i = 0; i < length; i++) {
    handle = Dart_IntegerToInt64(Dart_ListGetAt(list, i), &byte);
    if (Dart_IsError(handle)) Dart_PropagateError(handle);

    bytes[i] = static_cast<char>(byte);
  }

  if (write(static_cast<int>(sockfd), bytes, length) != length) {
    free(bytes);
    Dart_Handle error = NewDartExceptionWithMessage(
        "dart:io", "SocketException", "Error writing to socket");
    if (Dart_IsError(error)) Dart_PropagateError(error);
    Dart_ThrowException(error);
  }
  free(bytes);
}

Dart_NativeFunction ResolveName(Dart_Handle name, int argc,
                                bool* auto_setup_scope) {
  if (!Dart_IsString(name)) return NULL;
  Dart_NativeFunction result = NULL;
  const char* cname;
  Dart_Handle handle;

  handle = Dart_StringToCString(name, &cname);
  if (Dart_IsError(handle)) Dart_PropagateError(handle);

  if (strcmp("connect", cname) == 0) result = sync_connect;
  if (strcmp("close", cname) == 0) result = sync_close;
  if (strcmp("read", cname) == 0) result = sync_read;
  if (strcmp("write", cname) == 0) result = sync_write;

  return result;
}

Dart_Handle NewDartExceptionWithMessage(const char* library_url,
                                        const char* exception_name,
                                        const char* message) {
  // Create a Dart Exception object with a message.
  Dart_Handle type =
      Dart_GetType(Dart_LookupLibrary(Dart_NewStringFromCString(library_url)),
                   Dart_NewStringFromCString(exception_name), 0, NULL);

  if (Dart_IsError(type)) {
    Dart_PropagateError(type);
  }
  if (message != NULL) {
    Dart_Handle args[1];
    args[0] = Dart_NewStringFromCString(message);
    if (Dart_IsError(args[0])) {
      Dart_PropagateError(args[0]);
    }
    return Dart_New(type, Dart_Null(), 1, args);
  } else {
    return Dart_New(type, Dart_Null(), 0, NULL);
  }
}
