import 'dart:async';

import 'package:async_notify/async_notify.dart';
import 'package:meta/meta.dart';

import 'timeout_cancellation_exception.dart';

/// 非同期処理のキャンセル不可能な1ブロック処理
/// このブロック完了後、FutureContextは復帰チェックを行い、必要であればキャンセル等を行う.
typedef FutureSuspendBlock<T> = Future<T> Function(FutureContext context);

/// 非同期（Async）状態を管理する.
/// FutureContextの目標はキャンセル可能な非同期処理のサポートである.
///
/// 処理終了後、必ず [close] をコールする必要がある.
///
/// 開発者はFutureContext.suspend()に関数を渡し、実行を行う.
/// suspend()は実行前後にFutureContextの状態を確認し、必要であればキャンセル等の処理や中断を行う.
///
/// NOTE. 2021-05
/// Flutter 2.2(Dart 2.12)現在、言語仕様としてKotlinのSuspend関数のような状態管理を行えない.
/// そのため、開発者側で適度にブロックを区切って実行を行えるようサポートする.
///
/// KotlinにはCoroutineDispatcherのようなさらに上位（周辺）の仕組みがあるが、
/// 目的に対してオーバースペックであるため実装を見送る.
///
/// 処理が冗長になることと、Dart標準からかけ離れていくリスクがあるため、
/// 使用箇所については慎重に検討が必要.
class FutureContext {
  /// 親も含めた管理を簡易化するために、グローバルで１つのNotifyを使用する.
  @internal
  static final systemNotify = Notify();

  /// 親Context.
  final FutureContext? _parent;

  /// 現在の状態
  var _state = _ContextState.active;

  /// 空のFutureContextを作成する.
  FutureContext() : _parent = null;

  /// 指定した親Contextを持つFutureContextを作成する.
  FutureContext.child({required FutureContext parent}) : _parent = parent;

  /// 処理が継続中の場合trueを返却する.
  bool get isActive {
    // 親がアクティブでないなら、このContextもアクティブではない.
    if (_parent?.isActive == false) {
      return false;
    }
    return _state == _ContextState.active;
  }

  /// 処理がキャンセル済みの場合true.
  bool get isCanceled {
    if (_parent?.isCanceled == true) {
      // 親がキャンセル状態なら、すでにキャンセル状態である
      return true;
    }
    return _state == _ContextState.canceled;
  }

  /// Futureをキャンセルする.
  /// すでにキャンセル済みの場合は何もしない.
  Future close() => _closeWith(next: _ContextState.canceled);

  /// 指定時間Contextを停止させる.
  /// delayed()の最中にキャンセルが発生した場合、速やかにContext処理は停止する.
  ///
  /// e.g.
  /// context.delayed(Duration(seconds: 1));
  Future delayed(final Duration duration) async =>
      suspend((context) => systemNotify.delay(duration));

  /// 非同期処理の特定1ブロックを実行する.
  /// これはFutureContext<T>の実行最小単位として機能する.
  /// suspend内部では実行開始時・終了時にそれぞれAsyncContextのステートチェックを行い、
  /// 必要であれば例外を投げる等の中断処理を行う.
  ///
  /// 開発者は可能な限り細切れに suspend() に処理を分割することで、
  /// 処理の速やかな中断のサポートを受けることができる.
  ///
  /// suspend()関数は1コールのオーバーヘッドが大きいため、
  /// 内部でキャンセル処理が必要なほど長い場合に利用する.
  Future<T2> suspend<T2>(FutureSuspendBlock<T2> block) async {
    systemNotify.notify();
    _resume();
    (T2?, Exception?)? result;
    unawaited(() async {
      try {
        result = (await block(this), null);
      } on Exception catch (e) {
        result = (null, e);
      } finally {
        systemNotify.notify();
      }
    }());

    // タスクが完了するまで待つ
    while (result == null) {
      await systemNotify.wait();
      _resume();
    }

    final item = result?.$1;
    final exception = result?.$2;

    if (exception != null) {
      throw exception;
    } else {
      return item as T2;
    }
  }

  /// タイムアウト付きの非同期処理を開始する.
  ///
  /// タイムアウトが発生した場合、
  /// block()は [TimeoutCancellationException] が発生して終了する.
  Future<T2> withTimeout<T2>(
    Duration timeout,
    FutureSuspendBlock<T2> block,
  ) async {
    final child = FutureContext.child(parent: this);
    try {
      return await child.suspend(block).timeout(timeout);
    } on TimeoutException catch (e) {
      throw TimeoutCancellationException(
        e.message ?? 'withTimeout<$T2>',
        timeout,
      );
    } finally {
      unawaited(child.close());
    }
  }

  Future _closeWith({
    required _ContextState next,
  }) async {
    if (_state != _ContextState.active) {
      return;
    }
    _state = next;
  }

  /// 非同期処理の状態をチェックし、必要であれはキャンセル処理を発生させる.
  void _resume() {
    _parent?._resume(); // 親のResumeチェック

    // 自分自身のResume Check.
    if (_state == _ContextState.canceled) {
      throw CancellationException('FutureContext is canceled.');
    }
  }
}

enum _ContextState {
  active,
  canceled,
}
