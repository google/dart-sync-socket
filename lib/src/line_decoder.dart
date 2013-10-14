part of sync.socket;

const int LINE_TERMINATOR = 10;

typedef void LineDecoderCallback(
    String line, int bytesRead, _LineDecoder decoder);

class _LineDecoder {
  BytesBuilder _unprocessedBytes = new BytesBuilder();

  int expectedByteCount = -1;

  final LineDecoderCallback _callback;

  _LineDecoder.withCallback(this._callback);

  void add(List<int> chunk) {
    while (chunk.isNotEmpty) {
      int splitIndex = -1;

      if (expectedByteCount > 0) {
        splitIndex = expectedByteCount - _unprocessedBytes.length;
      } else {
        splitIndex = chunk.indexOf(LINE_TERMINATOR) + 1;
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
