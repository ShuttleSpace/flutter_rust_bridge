import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter_rust_bridge/src/codec/base.dart';
import 'package:flutter_rust_bridge/src/generalized_isolate/generalized_isolate.dart';
import 'package:flutter_rust_bridge/src/utils/port_generator.dart';

/// The Rust `StreamSink<T>` on the Dart side.
class RustStreamSink<T> {
  _State<T>? _state;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  late final Stream<T> _stream;

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  RustStreamSink() {
    _stream = _controller.stream.listenAndBuffer();
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  String setupAndSerialize({required BaseCodec<T, dynamic, dynamic> codec}) {
    _state ??= _setup(codec, _controller);
    return serializeNativePort(_state!.receivePort.sendPort.nativePort);
  }

  /// The Dart stream for the Rust sink
  Stream<T> get stream => _stream;
}

class _State<T> {
  final ReceivePort receivePort;

  const _State(this.receivePort);
}

_State<T> _setup<T>(
    BaseCodec<T, dynamic, dynamic> codec, StreamController<T> controller) {
  final portName = ExecuteStreamPortGenerator.create('RustStreamSink');
  final receivePort = broadcastPort(portName);

  unawaited(() async {
    try {
      await for (final raw in receivePort) {
        try {
          controller.add(codec.decodeObject(raw));
        } on CloseStreamException {
          break;
        } catch (e, s) {
          controller.addError(e, s);
          break;
        }
      }
    } finally {
      await controller.close();
    }
  }());

  return _State(receivePort);
}
