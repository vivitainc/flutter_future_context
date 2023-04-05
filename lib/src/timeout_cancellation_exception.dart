import 'dart:async';

import 'package:async_notify/async_notify.dart';

/// 非同期処理のタイムアウト時に投げられる.
class TimeoutCancellationException extends CancellationException
    implements TimeoutException {
  @override
  final Duration duration;

  TimeoutCancellationException(String message, this.duration) : super(message);
}
