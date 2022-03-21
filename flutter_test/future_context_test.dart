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
