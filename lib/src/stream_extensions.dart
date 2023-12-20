import 'dart:async';

import 'package:async_notify/async_notify.dart';
import 'package:rxdart/rxdart.dart';

import 'future_context.dart';

extension StreamWithContext<T> on Stream<T> {
  static final _notify = PublishSubject<dynamic>();

  /// StreamとFutureContextを統合して新しいStreamを作成する.
  ///
  /// [context] がキャンセルされたタイミングで、このStreamもキャンセルされる.
  /// キャンセルされる場合、 [CancellationException] が投げられる点に注意すること.
  Stream<T> withContext(FutureContext context) {
    final key = this;
    var done = false;

    // データ本体、キャンセルチェック、終了通知の３つから合成される.
    return CombineLatestStream.combine3(
      doOnDone(() {
        done = true;
        _notify.add(this);
      }),
      context.isCanceledStream,
      // 終了通知がない場合、Streamがcloseされずにフリーズされてしまう.
      // notifyを流すことで、確実にstreamを終了させる.
      ConcatStream([
        Stream.value(null),
        _notify.stream.where((event) => event == key),
      ]),
      (a, b, _) => (a, b),
    ).takeWhile((element) => !done).map((event) {
      final value = event.$1;
      final isCanceled = event.$2;
      if (isCanceled) {
        throw CancellationException('${context.toString()} is canceled');
      }
      return value;
    });
  }
}
