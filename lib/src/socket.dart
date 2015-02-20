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

part of sync.socket;

// functions to interface with native library
int _connect(String host, String service) native 'connect';
void _close(int sockfd) native 'close';
void _write(int sockfd, List<int> bytes) native 'write';
List<int> _read(int sockfd, int length) native 'read';

/**
 * A simple synchronous socket.
 */
class SocketSync {

  static const int DEFAULT_CHUNK_SIZE = 4096;

  int _sockfd;
  bool _open;

  /**
   * Creates a new socket connected to [host]:[port].
   */
  SocketSync(String host, int port) {
    _sockfd = _connect(host, port.toString());
    _open = true;
  }

  /**
   * Writes [bytes] to the socket.
   */
  void writeAsBytes(List<int> bytes) {
    _checkOpen();
    _write(_sockfd, bytes);
  }

  /**
   * Writes [obj].toString() to socket encoded with [encoding].
   */
  void writeAsString(Object obj, {Encoding encoding: UTF8}) {
    writeAsBytes(encoding.encode(obj.toString()));
  }

  /**
   * If [all] is true, then reads all remaining data on socket and closes it.
   * Otherwise reads up to [chunkSize] bytes.
   */
  List<int> readAsBytes({bool all: true, chunkSize: DEFAULT_CHUNK_SIZE}) {
    _checkOpen();
    if (all) {
      var data = new BytesBuilder();
      var newBytes;
      while ((newBytes = _read(_sockfd, chunkSize)).length > 0) {
        data.add(newBytes);
      }
      close();
      return data.takeBytes();
    } else {
      return _read(_sockfd, chunkSize);
    }
  }

  /**
   * Reads all remaining daata on socket and closes it, using [encoding] to
   * transform data into a [String].
   */
  String readAsString({Encoding encoding: UTF8}) =>
      encoding.decode(readAsBytes());

  void close() {
    if (_open) {
       _close(_sockfd);
       _open = false;
    }
  }

  void _checkOpen() {
    if (!_open) {
      throw new StateError('socket has been closed');
    }
  }
}
