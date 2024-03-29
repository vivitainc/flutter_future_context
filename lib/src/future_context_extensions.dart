import 'dart:async';

import 'package:async_notify/async_notify.dart';

import 'future_context.dart';

/// 指定した [context] を使用してsuspend関数を実行する.
/// 実行中に [context] がキャンセルされた場合、この関数は [CancellationException] を投げて早期終了する.
///
/// contextがnullである場合、空のFutureContextが生成される.
/// 生成された場合は自動的に [FutureContext.close] がコールされる.
///
/// suspend()関数は1コールのオーバーヘッドが大きいため、
/// 内部でキャンセル処理が必要なほど長い場合に利用する.
Future<T> withContext<T>(
  FutureContext? context,
  FutureSuspendBlock<T> block,
) async {
  final c = context ?? FutureContext();
  try {
    return await c.suspend(block);
  } finally {
    if (context == null) {
      await c.close();
    }
  }
}

/// 指定した [contexts] を使用してsuspend関数を実行する.
/// 実行中に [contexts] のいずれかがキャンセルされた場合、この関数は [CancellationException] を投げて早期終了する.
///
/// suspend()関数は1コールのオーバーヘッドが大きいため、
/// 内部でキャンセル処理が必要なほど長い場合に利用する.
Future<T> withContextGroup<T>(
  Iterable<FutureContext> contexts,
  FutureSuspendBlock<T> block,
) async {
  final c = FutureContext.group(contexts);
  try {
    return await c.suspend(block);
  } finally {
    await c.close();
  }
}

/// 指定した [context] を使用してsuspend関数を実行する.
/// 実行中に [context] がキャンセルされた場合、この関数は [CancellationException] を投げて早期終了する.
/// また、指定した [timeout] が経過した場合は [TimeoutException] を投げて早期終了する.
///
/// contextがnullである場合、空のFutureContextが生成される.
/// 生成された場合は自動的に [FutureContext.close] がコールされる.
///
/// suspend()関数は1コールのオーバーヘッドが大きいため、
/// 内部でキャンセル処理が必要なほど長い場合に利用する.
Future<T> withTimeout<T>(
  FutureContext? context,
  Duration timeout,
  FutureSuspendBlock<T> block,
) async {
  final c = context ?? FutureContext();
  try {
    return await c.withTimeout(timeout, block);
  } finally {
    if (context == null) {
      await c.close();
    }
  }
}
