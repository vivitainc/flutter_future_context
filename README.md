future_context

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
context.dispose();
```
