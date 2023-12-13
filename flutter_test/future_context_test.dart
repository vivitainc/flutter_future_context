import 'dart:async';

import 'package:async_notify/async_notify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_context/future_context.dart';

void main() {
  late FutureContext context;
  setUp(() async {
    debugPrint('setUp');
    context = FutureContext();

    unawaited(() async {
      await for (final cancel in context.isCanceledStream) {
        debugPrint('isCanceled: $cancel');
      }
    }());
  });
  tearDown(() async {
    debugPrint('context close');
    await context.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    debugPrint('tearDown');
  });

  test('suspend', () async {
    final value = await context.suspend((context) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return 100;
    });
    expect(value, 100);
  }, timeout: const Timeout(Duration(seconds: 2)));

  test('delayed', () async {
    final sw = Stopwatch();
    sw.start();
    await context.delayed(const Duration(milliseconds: 110));
    sw.stop();
    debugPrint('elapsedMilliseconds: ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(110));
    expect(sw.elapsedMilliseconds, lessThan(120));
  });

  test('timeout(success)', () async {
    final result = await context.withTimeout<int>(
      const Duration(seconds: 10),
      (context) async {
        await context.delayed(const Duration(seconds: 1));
        return 1;
      },
    );
    expect(result, 1);
  });

  test('timeout', () async {
    try {
      await context.withTimeout<void>(
        const Duration(seconds: 1),
        (context) async {
          await context.delayed(const Duration(seconds: 10));
        },
      );
      fail('not calling');
    } on TimeoutCancellationException catch (_) {
      // OK!
    }
  });
  test('timeout(Blocking)', () async {
    try {
      await context.withTimeout<void>(
        const Duration(seconds: 1),
        (context) async {
          await Future<void>.delayed(const Duration(seconds: 10));
        },
      );
      fail('not calling');
    } on TimeoutCancellationException catch (e) {
      debugPrint('$e');
    }
  });

  test('cancel', () async {
    unawaited(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await context.close();
    }());
    try {
      final value = await context.suspend((context) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return 100;
      });
      fail('always Nothing: $value');
    } on CancellationException catch (e, stackTrace) {
      debugPrint('throws CancellationException');
      debugPrint('$e, $stackTrace');
      // OK!
    }
  });

  test('group', () async {
    final ctx2 = FutureContext();
    final groupContext = FutureContext.group({context, ctx2});

    expect(ctx2.isActive, isTrue);
    expect(groupContext.isActive, isTrue);
    expect(ctx2.isCanceled, isFalse);
    expect(groupContext.isCanceled, isFalse);

    // 親をキャンセル
    await ctx2.close();

    expect(ctx2.isActive, isFalse);
    expect(groupContext.isActive, isFalse);
    expect(ctx2.isCanceled, isTrue);
    expect(groupContext.isCanceled, isTrue);
  });
}
