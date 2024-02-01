## 0.0.2+12

* Fix: FutureContext.delayed()内部でisCanceledStreamがリークする問題を修正
* Fix: FutureContext.delayed()内部でタイムアウトが正常に発生しない場合がある問題を修正
* Fix: FutureContext.suspend()内部でisCanceledStreamキャンセルできない場合がある問題を修正

## 0.0.2+9

* Fix: Webビルドでdart2jsがクラッシュする問題を修正

## 0.0.2+8

* Fix: Stream.withContext()の内部で２回以上例外が発生する場合がある問題を修正

## 0.0.2+7

* Chg: 中断処理の最適化
* Del: TimeoutCanellationExceptionを削除してTimeoutExceptionに統合

## 0.0.2+6

* Fix: キャンセルメッセージが正常に反映されない場合がある問題を修正

## 0.0.2+5

* Add: FutureContextのキャンセル状況をStreamで取得するpropertyを追加

## 0.0.2+4

* Fix: Stream.withContext()で正常に例外が伝搬しない問題を修正

## 0.0.2+3

* Add: withContextGroup()トップレベル関数を追加

## 0.0.2+2

* Fix: 軽微な問題を修正

## 0.0.2+1

* Chg: FutureContext.group()を追加
* Chg: FutureContext.suspend()をinternalに変更し、 withContext(), withTimeout()のトップレベル関数を追加

## 0.0.2

* Chg: FutureContext実装を整理
* Chg: Stream操作をExtensionに分離
* Del: 不要実装を削除

## 0.0.1+2

* Chg: FutureContext.withTimeout()の実装をシンプルに変更

## 0.0.1+1

* Fix: FutureContext.withTimeout()のキャンセルが機能しない問題を修正

## 0.0.1

* Beta Release.
