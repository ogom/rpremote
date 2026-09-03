# 大仙古墳 イルミネーション・Oximeterサンプル

[English](README.md)

Raspberry Pi Pico 2を使い、大仙古墳模型の572個のLEDイルミネーションとMAX30102による心拍数・SpO2推定を実行するPicoRubyサンプルです。終了時にはすべてのLEDを消灯し、センサーをshutdownします。

> Oximeter機能は学習・演出用であり、医療機器ではありません。推定した心拍数やSpO2を診断、治療判断、安全監視に使用しないでください。

## はじめに

[ハードウェアと安全上の注意](docs/hardware.ja.md)に従って配線とLED用電源を準備し、リポジトリルートでビルド、ファームウェアの書き込み、サンプルの実行をまとめて行います。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

既定のアプリケーションは`:tests`イルミネーションセットリストを実行します。完了後に`DAISENKOFUN mode=illumination event=done status=ok`が表示されれば成功です。ファームウェアを書き込み後の反復作業と、`rpremote exec`による最軽量の実機確認は[開発手順](docs/development.ja.md)を参照してください。

## 使い方

- [開発手順](docs/development.ja.md) — 書き込み、`rpremote exec`、編集・実行の反復、ファームウェア再ビルド、シリアルログ
- [動作モードと設定](docs/modes.ja.md) — イルミネーション、Oximeter、複合動作、GPIO、輝度、セットリスト
- [ハードウェアと安全上の注意](docs/hardware.ja.md) — 電源要件と配線

## 参考資料

- [イルミネーション一覧](docs/illuminations.ja.md) — 選択可能な全パターン
- [LED配置](docs/led_layout.ja.md) — 模型上の572個のLEDアドレス
- [構造確認資料](docs/structure.ja.md) — 模型で扱う大仙古墳の要素
- [mrbgem移管の記録](docs/mrbgem_migration.ja.md) — 読み込み方式と移管の検証記録
