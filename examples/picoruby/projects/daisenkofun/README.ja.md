# 大仙古墳 イルミネーション・Oximeter・音楽サンプル

[English](README.md)

Raspberry Pi Pico 2を使い、大仙古墳模型の572個のLEDイルミネーションとMAX30102による心拍数・SpO2推定を実行するPicoRubyサンプルです。複合モードでは、生体パルスを三重の濠を巡るPWMの輪唱とLED表示へ変換し、8拍から固有の「心拍の署名」を生成できます。終了時にはすべてのLEDを消灯し、センサーをshutdownします。

現在のCoCに基づくmrbgem構成は、Pico 2、MAX30102、状態LED、572個のイルミネーション、PWMブザーを接続した実機で動作確認済みです。

> Oximeter機能は学習・演出用であり、医療機器ではありません。推定した心拍数やSpO2を診断、治療判断、安全監視に使用しないでください。

## はじめに

[ハードウェアと安全上の注意](docs/hardware.ja.md)に従って配線とLED用電源を準備し、リポジトリルートでビルド、ファームウェアの書き込み、サンプルの実行をまとめて行います。

```sh
rpremote deploy examples/picoruby/projects/daisenkofun
```

現在の[`main.rb`](main.rb)は`:combined`モードで60秒間測定し、572個のLEDにGP14、MAX30102にGP16/GP17、状態LED用SPIにGP2/GP3、ブザーにGP18を使います。8拍ごとに`:heartbeat_signature`を演奏するので、MAX30102へ指先を置き、音と濠LEDの同期、署名後の輪唱復帰、終了時の`event=verification`を確認してください。`Application::Config`の全項目は[動作モードと設定](docs/modes.ja.md)、反復作業は[開発手順](docs/development.ja.md)を参照してください。

## mrbgem構成

プロジェクト内のmrbgemは、gem名、require名、実装ディレクトリ、ルート名前空間を単数形のコンポーネント名で一致させるCoCに統一しています。

| mrbgem | require／実装ディレクトリ | ルート名前空間 | 主な責務 |
| --- | --- | --- | --- |
| `picoruby-daisenkofun-application` | `daisenkofun-application`／`mrblib/daisenkofun-application/` | `Daisenkofun::Application` | 設定、構築、実行、検証、終了処理 |
| `picoruby-daisenkofun-runtime` | `daisenkofun-runtime`／`mrblib/daisenkofun-runtime/` | `Daisenkofun::Runtime` | 共通Clock、Logger、協調イベントループ |
| `picoruby-daisenkofun-oximeter` | `daisenkofun-oximeter`／`mrblib/daisenkofun-oximeter/` | `Daisenkofun::Oximeter` | MAX30102のライフサイクル、測定、イベント、状態LED |
| `picoruby-daisenkofun-musical` | `daisenkofun-musical`／`mrblib/daisenkofun-musical/` | `Daisenkofun::Musical` | Subscriber、Translator、Planner、PWM Output |
| `picoruby-daisenkofun-illumination` | `daisenkofun-illumination`／`mrblib/daisenkofun-illumination/` | `Daisenkofun::Illumination` | LED Device、Display、再生、生体パターン |

## 使い方

- [開発手順](docs/development.ja.md) — 書き込み、`rpremote exec`、編集・実行の反復、ファームウェア再ビルド、シリアルログ
- [動作モードと設定](docs/modes.ja.md) — イルミネーション、Oximeter、複合動作、GPIO、輝度、セットリスト
- [ハードウェアと安全上の注意](docs/hardware.ja.md) — 電源要件と配線
- [生体パルスをPWMメロディーに変換する仕組み](docs/biometric_pwm_music.ja.md) — MAX30102、音高・音価・PWM duty、古墳の輪唱、心拍の署名、濠LED同期の構成

## 参考資料

- [イルミネーション一覧](docs/illuminations.ja.md) — 選択可能な全パターン
- [LED配置](docs/led_layout.ja.md) — 模型上の572個のLEDアドレス
- [構造確認資料](docs/structure.ja.md) — 模型で扱う大仙古墳の要素
- [mrbgem移管の記録](docs/mrbgem_migration.ja.md) — 読み込み方式と移管の検証記録
