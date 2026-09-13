# 大仙古墳 イルミネーション・Oximeter・音楽サンプル

[English](README.md)

Raspberry Pi Pico 2で大仙古墳模型の572個のLEDを制御し、MAX30102で推定した心拍数とSpO₂を光とPWM音へ変換するPicoRubyサンプルです。イルミネーション単独、Oximeter単独、両者を同期する複合モードを選べます。

> Oximeter機能は学習・演出用であり、医療機器ではありません。推定値を診断、治療判断、安全監視に使用しないでください。

## はじめに

[ハードウェアと安全上の注意](docs/hardware.ja.md)に従って配線とLED用電源を準備し、リポジトリルートから実行します。mrbgemを初めて組み込むときはビルドも指定してください。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun --build
```

現在の[`main.rb`](main.rb)は`:combined`モードで60秒間動作します。MAX30102へ指先を置き、心拍に合わせた音と濠LEDを確認してください。

## ガイド

- [ハードウェアと安全上の注意](docs/hardware.ja.md) — 電源、配線、アンプ
- [動作モードと設定](docs/modes.ja.md) — modeと`Application::Config`
- [開発手順](docs/development.ja.md) — ビルド、実行、テスト、実機確認
- [mrbgemを使う理由](docs/mrbgem_migration.ja.md) — 実行時ロードとの比較と設計判断
- [生体パルスと音楽](docs/biometric_pwm_music.ja.md) — 心拍、SpO₂、音、光の関係
- [イルミネーション一覧](docs/illuminations.ja.md) — パターンとsetlist
- [LED配置](docs/led_layout.ja.md) — 572個のLEDアドレス
- [構造確認資料](docs/structure.ja.md) — 模型で扱う大仙古墳の要素

## 構成

プロジェクトは`Application`、`Runtime`、`Oximeter`、`Musical`、`Illumination`の5つのローカルmrbgemで構成されます。各mrbgemは同名の`Daisenkofun`名前空間を持ち、ファームウェアへ組み込まれます。
