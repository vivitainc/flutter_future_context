import 'dart:async';

import 'package:async_notify/async_notify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_context/future_context.dart';

void main() {
  late FutureContext context;
  setUp(() async {
    context = FutureContext();
  });
  tearDown(() async {
    await context.dispose();
  });

  test('suspend', () async {
    final value = await context.suspend((context) async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return 100;
    });
    expect(value, 100);
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
      context.cancel('FutureContext.cancel()');
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
}
