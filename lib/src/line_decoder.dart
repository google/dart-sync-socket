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

// '\n' character
const int _LINE_TERMINATOR = 10;

typedef void _LineDecoderCallback(
    String line, int bytesRead, _LineDecoder decoder);

class _LineDecoder {
  BytesBuilder _unprocessedBytes = new BytesBuilder();

  int expectedByteCount = -1;

  final _LineDecoderCallback _callback;

  _LineDecoder.withCallback(this._callback);

  void add(List<int> chunk) {
    while (chunk.isNotEmpty) {
      int splitIndex = -1;

      if (expectedByteCount > 0) {
        splitIndex = expectedByteCount - _unprocessedBytes.length;
      } else {
        splitIndex = chunk.indexOf(_LINE_TERMINATOR) + 1;
      }

      if (splitIndex > 0 && splitIndex <= chunk.length) {
        _unprocessedBytes.add(chunk.sublist(0, splitIndex));
        chunk = chunk.sublist(splitIndex);
        expectedByteCount = -1;
        _process(_unprocessedBytes.takeBytes());
      } else {
        _unprocessedBytes.add(chunk);
        chunk = [];
      }
    }
  }

  void _process(List<int> line) =>
      _callback(UTF8.decoder.convert(line), line.length, this);

  int get bufferedBytes => _unprocessedBytes.length;

  void close() => _process(_unprocessedBytes.takeBytes());
}
