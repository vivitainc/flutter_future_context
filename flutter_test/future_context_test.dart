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

    // キャンセル済みなので、これは常にtrueである
    expect(
      await context.isCanceledStream.where((event) => event).first,
      isTrue,
    );
    debugPrint('tearDown');
  });

  group('FutureContext.suspend', () {
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
    test('cancel', () async {
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await context.close();
      }());
      try {
        final value = await context.suspend((context) async {
          try {
            await context.delayed(const Duration(seconds: 10));
            return 100;
          } finally {
            debugPrint('finish suspend');
          }
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
  });

  group('FutureContext.timeout', () {
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
  });

  group('Stream', () {
    test('done', () async {
      final stream = Stream.periodic(
        const Duration(milliseconds: 100),
        (i) => i,
      ).takeWhile((element) => element < 10).withContext(context);
      var received = 0;
      await for (final v in stream) {
        ++received;
        debugPrint('stream: $v');
      }
      expect(received, 10);
    });
    test('cancel', () async {
      final stream = Stream.periodic(
        const Duration(milliseconds: 100),
        (i) => i,
      ).withContext(context);
      unawaited(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await context.close();
      }());
      var received = 0;
      try {
        await for (final v in stream) {
          ++received;
          debugPrint('stream: $v');
        }
        fail('always Nothing');
      } on CancellationException catch (e, stackTrace) {
        debugPrint('throws CancellationException');
        debugPrint('$e, $stackTrace');
        expect(received, isNot(equals(0)));
      }
    });

    test('error', () async {
      final stream = Stream.periodic(
        const Duration(milliseconds: 100),
        (i) {
          if (i < 10) {
            return i;
          }
          throw Exception('error');
        },
      ).takeWhile((element) => element < 10).withContext(context);
      try {
        await for (final v in stream) {
          debugPrint('stream: $v');
        }
        fail('always Nothing');
      } on Exception catch (e, stackTrace) {
        debugPrint('catch OK: $e, $stackTrace');
      }
    });
  });
}
