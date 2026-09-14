# 五稜郭イルミネーションとタンバリン

[English](README.md)

Raspberry Pi Pico 2で、五稜郭模型の380個のWS2812B、MPU6050、タッチスイッチ、PWMブザーを制御するPicoRubyプロジェクトです。イルミネーション、タンバリン、タッチ選択付き複合動作を楽しめます。

> 380個のLEDには大容量の外部5 V電源が必要です。Pico 2からLEDへ給電しないでください。

## はじめに

[ハードウェアと安全上の注意](docs/hardware.ja.md)に従って配線します。ルートの`Mrbgems`で5つのGoryokaku mrbgemを有効にし、ほかのプロジェクト固有mrbgemを無効にしてから、リポジトリルートで実行します。

```sh
rpremote mrbgems lock
rpremote deploy --build examples/picoruby/projects/goryokaku --timeout 120
```

現在の[`main.rb`](main.rb)は`:illumination`で`:highlights`を実行します。実行中断時も、終了処理でブザーを停止して全LEDを消灯します。

## ガイド

- [ハードウェアと安全上の注意](docs/hardware.ja.md) — 電源、配線、アンプ、MPU6050の向き
- [動作モードと設定](docs/modes.ja.md) — 3つのmode、タッチ選択、タンバリン演奏
- [イルミネーション一覧](docs/illuminations.ja.md) — 21パターンとsetlist
- [LED配置](docs/led_layout.ja.md) — 380個のアドレスと配線方向
- [構造確認資料](docs/structure.ja.md) — 五稜郭の構造と模型への対応
- [開発手順](docs/development.ja.md) — ビルド、実行、テスト、実機確認

## 動作モード

| mode | 動作 |
| --- | --- |
| `:illumination` | LED演出と「きらきら星」を再生する |
| `:musical` | Y-UPで振る／叩くタンバリンを音と光で演奏する |
| `:combined` | Y-UPのタッチで候補を選び、Z-UPのタッチで決定する |

プロジェクトは`Application`、`Runtime`、`Interaction`、`Musical`、`Illumination`の5つのローカルmrbgemとしてファームウェアへ組み込まれます。
