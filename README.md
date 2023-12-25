future_context

[![Github Actions](https://github.com/vivitainc/flutter_future_context/actions/workflows/flutter-package-test.yaml/badge.svg)](https://github.com/vivitainc/flutter_future_context/actions/workflows/flutter-package-test.yaml)

## Features

Flutterアプリの非同期処理キャンセル処理をサポートする.

* FutureContext
    Kotlin.coroutinesのようなキャンセル可能な非同期処理

## Usage

TODO.

```dart
final context = FutureContext();

// if you should cancel this `suspend` block.
// context.cancel();
final value = await context.suspend((context) async {
    // Very slow.
    return 100;
});

// finalyze
context.close();
```
