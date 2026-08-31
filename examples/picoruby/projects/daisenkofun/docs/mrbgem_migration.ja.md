# PicoRubyでイルミネーションを読み込む方法の検証

[English](mrbgem_migration.md)

大仙古墳プロジェクトでは、多数のイルミネーションをPicoRuby 4.0.3で読み込む方法を、次の順番で試しました。

1. 起動時にすべてのRubyソースを読み込む（一括ロード）
2. 実行する直前にRubyソースを読み込む（遅延ロード）
3. ホスト側でコンパイルした`.mrb`を読み込む（事前コンパイル）
4. イルミネーションをファームウェアへ組み込む

一括ロードと遅延ロードでは、どちらも実機上で多数の`.rb`をコンパイルする必要があり、安定しませんでした。事前コンパイルでは実機上のコンパイルを避けられましたが、ファイルを保持する期間に問題があり、連続実行に失敗しました。最終的に、Sandboxを介したファイル読み込みをやめ、イルミネーションをmrbgemとしてファームウェアへ組み込むことで、`Setlist::SHORT`の連続実行に成功しました。

この文書のコマンド、パス、ログ、`wait_ms`は各方式を検証した時点の記録です。現行の構成と設定は、プロジェクトの[`README.ja.md`](../README.ja.md)と[`setlist.rb`](../mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/setlist.rb)を参照してください。

## 1. 一括ロード

最初に、すべてのイルミネーションを起動時に`require`しました。

読み込むファイルが増えると、途中のファイルでコンパイルに失敗しました。

```text
Exception(vm_id=23): in `load_file':
/lib/daisenkofun/illuminations/fireworks.rb: compile failed (RuntimeError)
```

対象ファイルを修正すると、失敗位置は次の`golden_breath.rb`へ移りました。このことから、特定のファイルにあるRuby構文だけでなく、連続したコンパイルによる実機側リソースの消費も影響していると判断しました。

一括ロードには、実行開始後の`require`を減らせる利点があります。一方、このプロジェクトのようにファイル数が多い場合は、起動時にコンパイル処理とメモリ消費が集中します。

## 2. 遅延ロード

次に、一括ロードをやめて、各パターンを実行する直前に対応するファイルだけを読み込むようにしました。

```ruby
require "/lib/daisenkofun/illuminations/#{key}"
Illuminations.const_get(Setlist.class_name(key))
```

これにより起動時の負荷は減りましたが、複数のパターンを続けて実行すると、2番目のパターンを読み込む段階で停止しました。

```text
daisenkofun: pattern 1/30 moonlight wait_ms=15 loops=1
daisenkofun: pattern 2/30 starry_kofun wait_ms=15 loops=1
rpremote: run event=ERROR,class=Rpremote::Shell::TimeoutError,
message=timed out waiting for the R2P2 Shell after 20.0 seconds
```

パターン開始ログは`require`より前に出力されます。そのため、`starry_kofun`のログが表示されていても、そのクラスの読み込みが完了したことにはなりません。

### 遅延ロードが停止する理由

ファイルシステム上のライブラリを読み込む処理は、PicoRuby 4.0.3の`picoruby-require/mrblib/require.rb`で、おおむね次の順に実行されます。

1. `$LOADED_FEATURES`を確認する
2. 同名の`.mrb`、`.rb`の順にファイルを探す
3. `Sandbox.new("require")`でロード用のSandboxを生成する
4. `sandbox.load_file(path)`を実行する
5. `sandbox.terminate`を呼ぶ

`.rb`を読み込んだSandboxは、`picoruby-sandbox/mrblib/sandbox.rb`で次の処理を行います。

```text
.rbを読み込む
  -> 実機上でコンパイルする
  -> Sandboxタスクを実行する
  -> wait(timeout: nil)で完了を待つ
```

`wait(timeout: nil)`には内部タイムアウトがありません。Sandboxタスクが`DORMANT`または`SUSPENDED`へ進まない場合、呼び出し元の`require`も戻りません。

mruby/c向けSandboxの`picoruby-sandbox/src/mrubyc/sandbox.c`では、Sandbox VMに`flag_permanence = 1`を設定しています。読み込んだクラスのメソッドを後から呼び出せるよう、メソッドが参照するIREPは保持されます。また、`terminate`はタスクを終了状態にしますが、Sandboxの全リソースをその場で解放する`close`とは異なります。

このため、`.rb`を順番に読み込むたびに、実機上でのコンパイル、Sandboxタスクの生成、IREPの保持が発生します。複数のイルミネーションを連続して読み込むと、メモリ使用量や断片化の影響を受けます。

### 20秒タイムアウトは原因ではない

`rpremote run`は、最後の出力から指定秒数が経過すると`Ctrl-C`を送り、`Shell::TimeoutError`を返します。今回の処理順は次のとおりです。

```text
パターン開始ログ
  -> 遅延require
  -> 子Sandboxの完了を無期限に待つ
  -> シリアル出力とLED更新が停止する
  -> 20秒後にrpremoteがタイムアウトする
```

したがって、20秒という待機上限が停止の原因ではありません。実機が`require`から戻らず、R2P2シェルへ制御を返さなかった結果として、外側の`rpremote`がタイムアウトしています。`--timeout`を延長しても根本的な解決にはなりません。

### パスや文字列展開は正しい

次のコードでは、`key`から期待どおりの絶対パスが生成されます。

```ruby
require "/lib/daisenkofun/illuminations/#{key}"
```

実際に最初の`moonlight`は読み込まれ、点灯処理まで進みました。パスや文字列展開が誤っている場合は、最初の読み込みで`LoadError`になります。

### 停止位置の切り分け

遅延ロードの調査では、読み込みと実行の境界を確認するため、次のログを一時的に追加しました。

```ruby
puts "load start: #{key}"
require "/lib/daisenkofun/illuminations/#{key}"
puts "load done: #{key}"

klass = Illuminations.const_get(Setlist.class_name(key))
puts "call start: #{key}"
klass.new(display, wait_ms, loops).call
puts "call done: #{key}"
```

`load start`の後に`load done`が出なければ読み込み中、`call start`の後に`call done`が出なければパターン実行中の停止です。mruby/cのメモリ状況を確認できるビルドでは、各`require`の前後で`memory_statistics(false)`の`used`、`free`、`fragmentation`も記録できます。

## 3. 事前コンパイル

一括ロードと遅延ロードの結果を踏まえ、実機上で`.rb`をコンパイルせず、ホスト側で作成した`.mrb`を読み込む方法を試しました。

まず、評価範囲を`Setlist::SHORT`に限定しました。対象は7つのパターンと、共通基底の`base`です。

```text
base
structure_guide
divine_light
launch_fireworks
sunrise
dappled_light
triple_moat_mirror
water_ripples
```

各`.rb`は、実機と同じPicoRuby 4.0.3向けにコンパイルします。例は次のとおりです。

```console
$ rpremote dfu compile \
    examples/picoruby/projects/daisenkofun/mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/structure_guide.rb \
    --language-version 4.0.3 \
    --output examples/picoruby/projects/daisenkofun/mrbgems/daisenkofun-illuminations/mrblib/daisenkofun/illuminations/structure_guide.mrb
```

PicoRuby 4.0.3の`require`は、同名のファイルがある場合に`.mrb`を`.rb`より先に探します。そのため、既存の拡張子なしの`require`は変更する必要がありません。

```text
/lib/daisenkofun/illuminations/structure_guide.mrb
/lib/daisenkofun/illuminations/structure_guide.rb
```

生成した8ファイルは、PicoRuby 4.0.3用の`RITE0400`形式であることを確認し、実機の`:/lib/daisenkofun/illuminations`へ配置しました。これにより、実機上でのRubyソースコンパイルは避けられます。ただし、パターンごとにSandboxを生成する構造は残ります。

### 実行結果

`Setlist::SHORT`を実行すると、1番目の`structure_guide`は完了しましたが、2番目の`divine_light`で例外が発生しました。

```text
daisenkofun: pattern 1/7 structure_guide wait_ms=10 loops=1
daisenkofun: pattern 2/7 divine_light wait_ms=10 loops=1
daisenkofun: LEDs off

Unimplemented opcode (0x20) found (Exception)
rpremote: run event=ERROR,class=Rpremote::Shell::CommandError,
message=Ruby exception reported by R2P2
```

この実行では`--timeout 120`を指定していましたが、120秒を待たずにRuby例外が返りました。したがって、事前コンパイルの失敗原因もタイムアウトではありません。

### 事前コンパイルが失敗した理由

`0x20`はPicoRuby 4.0.3の命令表では`OP_SETMCNST`です。mruby/c VMでは、この命令は`picoruby-mrubyc/lib/mrubyc/src/vm.c`で未実装として扱われます。

しかし、生成した`divine_light.mrb`を逆アセンブルすると、正規の命令列に`OP_SETMCNST`は含まれていませんでした。Rubyコードから未実装命令が生成されたのではなく、VMが有効な命令列とは異なるメモリを読み取った結果、そこにあった`0x20`をopcodeとして解釈したと考えられます。

`.mrb`を読み込む処理には、次の特徴があります。

1. `picoruby-sandbox/mrblib/sandbox.rb`は、ファイル全体を文字列として読み込み、`Sandbox`の`@code`へ保持する
2. `exec_mrb`は命令列をコピーせず、文字列内部へのポインタをVMへ渡す
3. `picoruby-mrubyc/lib/mrubyc/src/load.c`のIREPも、命令列をコピーせず`.mrb`内を直接参照する
4. `require`が終了すると、ローカル変数だったSandboxへの参照がなくなる
5. GCがSandboxと`@code`を回収すると、クラスのメソッドが持つ命令ポインタは解放済み領域を指す

処理の流れは次のようになります。

```text
divine_light.mrbをrequire
  -> Sandbox内でクラスを定義する
  -> requireが終了する
  -> Sandboxと@codeが回収可能になる
  -> DivineLight#callが無効な命令ポインタを参照する
  -> 0x20を未実装opcodeとして検出する
```

`Sandbox`の`@code`は、そのSandboxのタスクが動作している間は`.mrb`を保持します。しかし、`require`で定義したメソッドをSandboxの終了後に呼び出す期間までは保持しません。したがって、個別の`.mrb`を遅延`require`するだけでは、安全に連続実行できませんでした。

## 4. ファームウェアへの組み込み

イルミネーション一式をローカルmrbgemの`mrbgems/daisenkofun-illuminations`へ移管し、ファームウェアへ組み込む方法を検証しました。この方法では、ファイルシステムから`.rb`や`.mrb`を読み込むSandboxを使用しません。

検証では、`Setlist::SHORT`のパターンを組み込み、次の点を確認しました。

1. `require "daisenkofun-illuminations"`で組み込み済みの全クラスを利用できること
2. `structure_guide`から`water_ripples`まで連続実行できること
3. Sandboxとファイルシステム上のソースに依存していないこと

mrbgemへの登録、lockの生成、PicoRuby 4.0.3／Pico 2向けファームウェアのビルドと実機への書き込みを行い、次のコマンドで確認しました。

```console
$ rpremote run examples/picoruby/projects/daisenkofun/main.rb --timeout 120
```

### 実行結果

`Setlist::SHORT`の全7パターンが設定順に実行されました。

次のログは検証時の`wait_ms=10`で実行した結果です。現行の`Setlist::SHORT`は`SHORT_FRAME_MS`を使用します。

```text
daisenkofun: start
daisenkofun: pattern 1/7 structure_guide wait_ms=10 loops=1
daisenkofun: pattern 2/7 divine_light wait_ms=10 loops=1
daisenkofun: pattern 3/7 launch_fireworks wait_ms=10 loops=1
daisenkofun: pattern 4/7 sunrise wait_ms=10 loops=1
daisenkofun: pattern 5/7 dappled_light wait_ms=10 loops=1
daisenkofun: pattern 6/7 triple_moat_mirror wait_ms=10 loops=1
daisenkofun: pattern 7/7 water_ripples wait_ms=10 loops=3
daisenkofun: LEDs off
daisenkofun: OK
rpremote: run event=EXECUTE_DONE,bytes=466
rpremote: run event=CLEANUP_START,path=/home/.rpremote-run.rb
rpremote: run event=CLEANUP_DONE
```

コンパイル失敗、停止、`Shell::TimeoutError`、`Unimplemented opcode`は発生していません。最後にLEDを消灯し、`daisenkofun: OK`、`EXECUTE_DONE`、`CLEANUP_DONE`まで到達したため、実行は正常に完了しています。

### 成功した理由

mrbgemの命令列はファームウェア内のプリビルドgemとして保持されます。ファイルシステムから読み込んだ一時的な文字列を命令列として参照しないため、事前コンパイル方式で発生した、GC後に無効な命令ポインタを参照する問題がありません。

また、実行時に各パターンの`.rb`をコンパイルせず、パターンごとのSandboxも生成しません。`Illuminations.const_get`でファームウェアへ組み込まれたクラスを取得して実行するため、一括ロードと遅延ロードで問題になった実機コンパイルの負荷も回避できました。

以上から、このプロジェクトではイルミネーションをmrbgemとしてファームウェアへ組み込む方法を採用します。
