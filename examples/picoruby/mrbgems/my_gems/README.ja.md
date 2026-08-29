# my_gems ローカルmrbgem

[English](README.md)

出力GPIOを`MyGems`で扱う、Pure Rubyのローカルmrbgemです。プロジェクト直下の`Mrbgems`から、ファイルを基準とした相対パスで読み込みます。

```ruby
gem path: "examples/picoruby/mrbgems/my_gems"
```

gemのrequire名は`my_gems`で、`picoruby-gpio`へ依存します。

## 使い方

```ruby
require "my_gems"
led = MyGems.new(pin: 25)
led.led_on
led.led_off
led.led_loop
```

`rpremote`で有限回の実機確認を行う例は[08_my_gems](../../education/08_my_gems/README.ja.md)を参照してください。
組み込み後にアプリだけを更新する例は[09_my_gems_dfu](../../education/09_my_gems_dfu/README.ja.md)を参照してください。
