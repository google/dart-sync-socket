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

import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:sync_socket/sync_socket.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

void main() {
  useCompactVMConfiguration();

  int port;

  // start echo server
  setUp(() {
    var response = new ReceivePort();
    Future<Isolate> remote = Isolate.spawn(startSimpleServer, response.sendPort);
    return response.first.then((_p) => port = _p);
  });

  test('simple connect/write/read', () {
    var socket = new SocketSync('localhost', port);
    socket.writeAsString('close');
    expect(socket.readAsString(), 'close');
    socket.close();
  });
}

void startSimpleServer(SendPort send) {
  io.ServerSocket.bind(io.InternetAddress.ANY_IP_V4, 0).then((server) {
    server.listen((socket) {
      socket.listen((data) {
        var str = new String.fromCharCodes(data);
        socket.write(str);
        if (str.endsWith('close')) {
          socket.close();
        }
      });
    });
    send.send(server.port);
  });
}

