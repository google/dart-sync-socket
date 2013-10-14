/*
Copyright 2013 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

part of sync.socket;

/**
 * A simple synchronous HTTP client.
 *
 * This is a two-step process. When a [HttpClientRequestSync] is returned the
 * underlying network connection has been established, but no data has yet been
 * sent. The HTTP headers and body can be set on the request, and close is
 * called to send it to the server and get the [HttpClientResponseSync].
 */
class HttpClientSync {
  HttpClientRequestSync getUrl(Uri uri) =>
      new HttpClientRequestSync._('GET', uri, false);

  HttpClientRequestSync postUrl(uri) =>
      new HttpClientRequestSync._('POST', uri, true);

  HttpClientRequestSync deleteUrl(uri) =>
      new HttpClientRequestSync._('DELETE', uri, false);

  HttpClientRequestSync putUrl(uri) =>
      new HttpClientRequestSync._('PUT', uri, true);
}

/**
 * HTTP request for a synchronous client connection.
 */
class HttpClientRequestSync {

  static const PROTOCOL_VERSION = '1.1';

  int get contentLength => hasBody ? _body.length : null;

  HttpHeaders _headers;

  HttpHeaders get headers {
    if (_headers == null) {
      _headers = new _HttpClientRequestSyncHeaders(this);
    }
    return _headers;
  }

  final String method;

  final Uri uri;

  final Encoding encoding = UTF8;

  final BytesBuilder _body;

  final SocketSync _socket;

  HttpClientRequestSync._(this.method, Uri uri, bool body)
      : this.uri = uri,
        this._body = body ? new BytesBuilder() : null,
        this._socket = new SocketSync(uri.host, uri.port);

  /**
   * Write content into the body.
   */
  void write(Object obj) {
    if (hasBody) {
      _body.add(encoding.encoder.convert(obj.toString()));
    } else {
      throw new StateError('write not allowed for method $method');
    }
  }

  bool get hasBody => _body != null;

  /**
   * Send the HTTP request and get the response.
   */
  HttpClientResponseSync close() {
    _socket.writeAsString('$method ${uri.path} HTTP/$PROTOCOL_VERSION\r\n');
    headers.forEach((name, values) {
      values.forEach((value) {
        _socket.writeAsString('$name: $value\r\n');
      });
    });
    _socket.writeAsString('\r\n');
    if (hasBody) {
      _socket.writeAsBytes(_body.takeBytes());
    }

    return new HttpClientResponseSync(_socket);
  }
}

class _HttpClientRequestSyncHeaders implements HttpHeaders {

  Map<String, List> _headers = <String, List<String>>{};

  final HttpClientRequestSync _request;
  ContentType contentType;

  _HttpClientRequestSyncHeaders(this._request);

  List<String> operator [](String name) {
    switch (name) {
      case HttpHeaders.ACCEPT_CHARSET:
        return [ 'utf-8' ];
      case HttpHeaders.ACCEPT_ENCODING:
        return [ 'identity' ];
      case HttpHeaders.CONNECTION:
        return [ 'close' ];
      case HttpHeaders.CONTENT_LENGTH:
        if (!_request.hasBody) {
          return null;
        }
        return [ contentLength ];
      case HttpHeaders.CONTENT_TYPE:
        if (contentType == null) {
          return null;
        }
        return [ contentType.toString() ];
      case HttpHeaders.HOST:
        return [ '$host:$port' ];
      default:
        var values = _headers[name];
        if (values == null || values.isEmpty) {
          return null;
        }
        return values.map((e) => e.toString()).toList(growable: false);
    }
  }

  void add(String name, Object value) {
    switch (name) {
      case HttpHeaders.ACCEPT_CHARSET:
      case HttpHeaders.ACCEPT_ENCODING:
      case HttpHeaders.CONNECTION:
      case HttpHeaders.CONTENT_LENGTH:
      case HttpHeaders.DATE:
      case HttpHeaders.EXPIRES:
      case HttpHeaders.IF_MODIFIED_SINCE:
      case HttpHeaders.HOST:
        throw new UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.CONTENT_TYPE:
        contentType = value;
        break;
      default:
        if (_headers[name] == null) {
          _headers[name] = [];
        }
        _headers[name].add(value);
    }
  }

  void remove(String name, Object value) {
    switch (name) {
      case HttpHeaders.ACCEPT_CHARSET:
      case HttpHeaders.ACCEPT_ENCODING:
      case HttpHeaders.CONNECTION:
      case HttpHeaders.CONTENT_LENGTH:
      case HttpHeaders.DATE:
      case HttpHeaders.EXPIRES:
      case HttpHeaders.IF_MODIFIED_SINCE:
      case HttpHeaders.HOST:
        throw new UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.CONTENT_TYPE:
        if(contentType == value) {
          contentType = null;
        }
        break;
      default:
        if (_headers[name] != null) {
          _headers[name].remove(value);
          if(_headers[name].isEmpty) {
            _headers.remove(name);
          }
        }
    }
  }

  void removeAll(String name) {
    switch (name) {
      case HttpHeaders.ACCEPT_CHARSET:
      case HttpHeaders.ACCEPT_ENCODING:
      case HttpHeaders.CONNECTION:
      case HttpHeaders.CONTENT_LENGTH:
      case HttpHeaders.DATE:
      case HttpHeaders.EXPIRES:
      case HttpHeaders.IF_MODIFIED_SINCE:
      case HttpHeaders.HOST:
        throw new UnsupportedError('Unsupported or immutable property: $name');
      case HttpHeaders.CONTENT_TYPE:
        contentType = null;
        break;
      default:
        _headers.remove(name);
    }
  }

  void set(String name, Object value) {
    removeAll(name);
    add(name, value);
  }

  String value(String name) {
    var val = this[name];
    if (val == null || val.isEmpty) {
      return null;
    } else if (val.length == 1) {
      return val[0];
    } else {
      throw new HttpException('header $name has more than one value');
    }
  }

  void forEach(void f(String name, List<String> values)) {
    var forEachFunc = (name) {
      var values = this[name];
      if (values != null && values.isNotEmpty) {
        f(name, values);
      }
    };

    [
      HttpHeaders.ACCEPT_CHARSET,
      HttpHeaders.ACCEPT_ENCODING,
      HttpHeaders.CONNECTION,
      HttpHeaders.CONTENT_LENGTH,
      HttpHeaders.CONTENT_TYPE,
      HttpHeaders.HOST ].forEach(forEachFunc);
    _headers.keys.forEach(forEachFunc);
  }

  bool get chunkedTransferEncoding => null;

  void set chunkedTransferEncoding(bool _chunkedTransferEncoding) {
    throw new UnsupportedError('chunked transfer is unsupported');
  }

  int get contentLength => _request.contentLength;

  void set contentLength(int _contentLength) {
    throw new UnsupportedError('content length is automatically set');
  }

  void set date(DateTime _date) {
    throw new UnsupportedError('date is unsupported');
  }

  DateTime get date => null;

  void set expires(DateTime _expires) {
    throw new UnsupportedError('expires is unsupported');
  }

  DateTime get expires => null;

  void set host(String _host) {
    throw new UnsupportedError('host is automatically set');
  }

  String get host => _request.uri.host;

  DateTime get ifModifiedSince => null;

  void set ifModifiedSince(DateTime _ifModifiedSince) {
    throw new UnsupportedError('if modified since is unsupported');
  }

  void noFolding(String name) {
    throw new UnsupportedError('no folding is unsupported');
  }

  bool get persistentConnection => false;

  void set persistentConnection(bool _persistentConnection) {
    throw new UnsupportedError('persistence connections are unsupported');
  }

  void set port(int _port) {
    throw new UnsupportedError('port is automatically set');
  }

  int get port => _request.uri.port;
}

/**
 * HTTP response for a cleint connection.
 */
class HttpClientResponseSync {
  int get contentLength => headers.contentLength;
  final HttpHeaders headers;
  final String reasonPhrase;
  final int statusCode;
  final String body;

  factory HttpClientResponseSync(SocketSync socket) {
    int statusCode;
    String reasonPhrase;
    StringBuffer body = new StringBuffer();
    Map<String, List<String>> headers = {};

    bool inHeader = false;
    bool inBody = false;
    int contentLength = 0;
    int contentRead = 0;

    void processLine(String line, int bytesRead, _LineDecoder decoder) {
      if (inBody) {
        body.write(line);
        contentRead += bytesRead;
        return;
      }
      if (inHeader) {
        if (line.trim().isEmpty) {
          inBody = true;
          if (contentLength > 0) {
            decoder.expectedByteCount = contentLength;
          }
          return;
        }
        int separator = line.indexOf(':');
        String name = line.substring(0, separator).toLowerCase().trim();
        String value = line.substring(separator + 1).trim();
        if (name == HttpHeaders.TRANSFER_ENCODING &&
            value.toLowerCase() != 'identity') {
          throw new UnsupportedError(
              'only identity transfer encoding is accepted');
        }
        if (name == HttpHeaders.CONTENT_LENGTH) {
          contentLength = int.parse(value);
        }
        if (!headers.containsKey(name)) {
          headers[name] = [];
        }
        headers[name].add(value);
        return;
      }
      if (line.startsWith('HTTP/1.1')) {
        statusCode = int.parse(line.substring(
            'HTTP/1.1 '.length, 'HTTP/1.1 '.length + 3));
        reasonPhrase = line.substring('HTTP/1.1 xxx '.length);
        inHeader = true;
      }
    };

    var lineDecoder = new _LineDecoder.withCallback(processLine);

    try {
      while (!inHeader || !inBody ||
          contentRead + lineDecoder.bufferedBytes < contentLength) {
        var bytes = socket.readAsBytes(all: false);

        if (bytes.length == 0) {
          break;
        }
        lineDecoder.add(bytes);
      }
    } finally {
      try {
        lineDecoder.close();
      } finally {
        socket.close();
      }
    }

    return new HttpClientResponseSync._(
        reasonPhrase: reasonPhrase,
        statusCode: statusCode,
        body: body.toString(),
        headers: headers);
  }

  HttpClientResponseSync._(
      {this.reasonPhrase, this.statusCode, this.body, headers})
      : this.headers = new _HttpClientResponseSyncHeaders(headers);
}

class _HttpClientResponseSyncHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers;

  _HttpClientResponseSyncHeaders(this._headers);

  List<String> operator [](String name) => _headers[name];

  void add(String name, Object value) {
    throw new UnsupportedError('Response headers are immutable');
  }

  bool get chunkedTransferEncoding => null;

  void set chunkedTransferEncoding(bool _chunkedTransferEncoding) {
    throw new UnsupportedError('Response headers are immutable');
  }

  int get contentLength {
    var val = value(HttpHeaders.CONTENT_LENGTH);
    if (val != null) {
      return int.parse(val, onError: (_) => null);
    }
    return val;
  }

  void set contentLength(int _contentLength) {
    throw new UnsupportedError('Response headers are immutable');
  }

  ContentType get contentType {
    var val = value(HttpHeaders.CONTENT_TYPE);
    if (val != null) {
      return ContentType.parse(val);
    }
    return null;
  }

  void set contentType(ContentType _contentType) {
    throw new UnsupportedError('Response headers are immutable');
  }

  void set date(DateTime _date) {
    throw new UnsupportedError('Response headers are immutable');
  }

  DateTime get date {
    var val = value(HttpHeaders.DATE);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  void set expires(DateTime _expires) {
    throw new UnsupportedError('Response headers are immutable');
  }

  DateTime get expires {
    var val = value(HttpHeaders.EXPIRES);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  void forEach(void f(String name, List<String> values)) => _headers.forEach(f);

  void set host(String _host) {
    throw new UnsupportedError('Response headers are immutable');
  }

  String get host {
    var val = value(HttpHeaders.HOST);
    if (val != null) {
      return Uri.parse(val).host;
    }
    return null;
  }

  DateTime get ifModifiedSince {
    var val = value(HttpHeaders.IF_MODIFIED_SINCE);
    if (val != null) {
      return DateTime.parse(val);
    }
    return null;
  }

  void set ifModifiedSince(DateTime _ifModifiedSince) {
    throw new UnsupportedError('Response headers are immutable');
  }

  void noFolding(String name) {
    throw new UnsupportedError('Response headers are immutable');
  }

  bool get persistentConnection => false;

  void set persistentConnection(bool _persistentConnection) {
    throw new UnsupportedError('Response headers are immutable');
  }

  void set port(int _port) {
    throw new UnsupportedError('Response headers are immutable');
  }

  int get port {
    var val = value(HttpHeaders.HOST);
    if (val != null) {
      return Uri.parse(val).port;
    }
    return null;
  }
  void remove(String name, Object value) {
    throw new UnsupportedError('Response headers are immutable');
  }

  void removeAll(String name) {
    throw new UnsupportedError('Response headers are immutable');
  }

  void set(String name, Object value) {
    throw new UnsupportedError('Response headers are immutable');
  }

  String value(String name) {
    var val = this[name];
    if (val == null || val.isEmpty) {
      return null;
    } else if (val.length == 1) {
      return val[0];
    } else {
      throw new HttpException('header $name has more than one value');
    }
  }
}
