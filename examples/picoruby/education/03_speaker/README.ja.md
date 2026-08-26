# 03 speaker

[English](README.md)

スイッチを押すたびに、圧電ブザーを1000 Hz、約3.05%デューティで200 ms鳴らします。`03_speaker.py`の`frequency=1000`、`duty_u16(2000)`、200 msと同じ条件です。

## 配線

- スイッチ: GP15（物理20番） -> タクトスイッチ -> GND（物理23番）
- GP18（物理24番） -> BTLアンプの入力
- BTLアンプの`OUT+` -> 圧電ブザーの`+`
- BTLアンプの`OUT-` -> 圧電ブザーの`-`

BTL出力の`OUT+`と`OUT-`はどちらもGNDへ接続しないでください。

最初はアンプのゲインまたは音量を低くして確認してください。

## 実行

```sh
rpremote run examples/picoruby/education/03_speaker/main.rb --timeout 15
```

押下ごとに「ピッ！」と鳴り、シリアル出力に表示されます。`Ctrl-C`で停止するとPWMを停止します。
