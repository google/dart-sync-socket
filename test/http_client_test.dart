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

library sync_socket.http_client_test;

import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:sync_socket/sync_socket.dart';
import 'package:unittest/vm_config.dart';
import 'package:unittest/unittest.dart';


void main() {
  useVMConfiguration();

  int port;

  group('HttpClientSync', () {
    setUp(() {
      var response = new ReceivePort();
      Isolate.spawn(startSimpleServer, response.sendPort);
      return response.first.then((_p) => port = _p);
    });

    test('simple get', () {
      HttpClientSync client = new HttpClientSync();
      var request = client.getUrl(new Uri.http('localhost:$port', '/'));
      var response = request.close();

      expect(response.statusCode, io.HttpStatus.NO_CONTENT);
      expect(response.body, '');
    });
  });
}

void startSimpleServer(SendPort send) {
  io.HttpServer.bind(io.InternetAddress.ANY_IP_V4, 0)
      .then((io.HttpServer server) {
        server.listen((io.HttpRequest request) {
          request.response.statusCode = io.HttpStatus.NO_CONTENT;
          request.response.close();
        });
        send.send(server.port);
      });
}
