import 'package:async_notify/async_notify.dart';
import 'package:rxdart/rxdart.dart';

import 'future_context.dart';

extension StreamWithContext<T> on Stream<T> {
  /// StreamとFutureContextを統合して新しいStreamを作成する.
  ///
  /// [context] がキャンセルされたタイミングで、このStreamもキャンセルされる.
  /// キャンセルされる場合、 [CancellationException] が投げられる点に注意すること.
  Stream<T> withContext(FutureContext context) async* {
    final channel =
        NotifyChannel<(T?, bool, Exception?)>(FutureContext.systemNotify);
    final subscription = map((event) => (event, false, null))
        .doOnError(
            (e, stackTrace) => channel.send((null, true, e as Exception)))
        .doOnDone(() => channel.send((null, true, null)))
        .listen((event) => channel.send(event));

    try {
      while (true) {
        final next = await context.suspend((context) => channel.receive());
        final item = next.$1;
        final done = next.$2;
        final exception = next.$3;
        if (exception != null) {
          throw exception;
        } else if (done) {
          return;
        } else {
          yield item as T;
        }
      }
    } finally {
      await subscription.cancel();
    }
  }
}
