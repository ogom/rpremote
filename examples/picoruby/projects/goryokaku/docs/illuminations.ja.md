# PicoRubyイルミネーション

この資料は、使用者が見たい演出を選べるように、指定するキー、模型上で見える演出、setlistの内容をまとめています。

## 一覧

| キー | タイトル | 演出 |
| ---- | -------- | ---- |
| `warm_white` | 五稜星の灯 | 星形本体を温白色で静かにフェードインします。 |
| `sakura_breathe` | 桜の呼吸 | 星形本体を桜色で呼吸するように明滅させます。 |
| `star_twinkle` | 星形のきらめき | 温白色の星形に白い光点を不規則に重ねます。 |
| `ravelin_pulse` | 半月堡の鼓動 | 南西正面の半月堡を水色で繰り返し明滅させます。 |
| `outer_comet` | 外周の彗星 | 金色の尾を引く光を堀外周に沿って周回させます。 |
| `rainbow` | 五彩の稜堡 | 星形の10辺を虹色で塗り分け、色を巡回させます。 |
| `parallel_left` | 左翼並列走査 | 左側グループの5辺へ異なる色の光を同時に進めます。 |
| `parallel_right` | 右翼並列走査 | 右側グループの5辺へ異なる色の光を同時に進めます。 |
| `full_zones` | 五稜郭全景 | 外周、半月堡、星形の順に点灯し、逆順に消灯します。 |
| `fireworks` | 五稜郭の花火 | 星形中心から光を広げ、外周を大きく発光させます。 |
| `kouhaku` | 紅白 | 赤と白の配置を反転しながら全体を点滅させます。 |
| `twinkle` | 金色のきらめき | 暗い背景へ金色の光点を不規則に重ねます。 |
| `shooting_star` | 流れ星 | 金色の尾を引く光をLED列全体へ流します。 |
| `breathing` | 金色の呼吸 | 全体の金色を滑らかに明滅させます。 |
| `constellation` | 星座 | 紅白の背景に金色の星をきらめかせます。 |
| `sakura_fubuki` | 桜吹雪 | 複数の桜色の花びらを全体へ不規則に舞わせます。 |
| `sakura_stream` | 桜の流れ | 桜色の尾を引く光をLED列全体へ流します。 |
| `sakura_gradient` | 桜色グラデーション | 複数の桜色を帯状に流します。 |
| `sakura_breathing` | 満開の呼吸 | 全体の桜色を滑らかに明滅させます。 |
| `hanami` | 花見 | 紅白の背景に桜色の光をきらめかせます。 |
| `mankai` | 満開 | 全体を複数の桜色で満たします。 |

## 実行設定

### 演出を選ぶ

[`main.rb`](../main.rb)の`Goryokaku::Application::Config`で、setlistまたは単独演出を選びます。次の設定は`:highlights`を1回再生します。

```ruby
mode: :illumination,
setlist_name: :highlights,
pattern_key: nil,
repeat: false
```

単独演出を見るときは`setlist_name: nil`にして、一覧のキーを`pattern_key`へ指定します。

```ruby
mode: :illumination,
setlist_name: nil,
pattern_key: :fireworks,
repeat: false
```

`setlist_name`と`pattern_key`は同時に指定できません。どちらも`nil`の場合は`:highlights`を再生します。`repeat: true`は停止されるまで光と曲を繰り返します。

### setlistの内容

| setlist | 向いている使い方 | 再生するキー（左から順） |
| --- | --- | --- |
| `:tests` | 配線後の短い点灯確認 | `warm_white` |
| `:highlights` | 星形、半月堡、外周と代表演出を短く見る | `warm_white` → `sakura_breathe` → `ravelin_pulse` → `outer_comet` → `rainbow` → `full_zones` → `fireworks` |
| `:story` | 城郭の灯から星空、紅白、桜、満開、花火への流れを鑑賞する | `warm_white` → `star_twinkle` → `ravelin_pulse` → `outer_comet` → `rainbow` → `kouhaku` → `shooting_star` → `constellation` → `sakura_fubuki` → `sakura_stream` → `sakura_gradient` → `sakura_breathing` → `hanami` → `mankai` → `fireworks` |
| `:showcase` | 登録済みの21演出をすべて確認する | `warm_white` → `sakura_breathe` → `star_twinkle` → `ravelin_pulse` → `outer_comet` → `rainbow` → `parallel_left` → `parallel_right` → `full_zones` → `kouhaku` → `twinkle` → `shooting_star` → `breathing` → `constellation` → `sakura_fubuki` → `sakura_stream` → `sakura_gradient` → `sakura_breathing` → `hanami` → `mankai` → `fireworks` |

`fireworks`は各setlistで3回繰り返し、`:showcase`の`outer_comet`は2周します。

### 再生時間と終了

各セットリストのエントリは`[key, wait_ms, loops]`で定義します。同じパターンでも、セットリストごとに待ち時間と繰り返し回数を変更できます。

```ruby
[:fireworks, 35, 3]
```

[`setlist.rb`](../mrbgems/goryokaku-illumination/mrblib/goryokaku-illumination/setlist.rb)では、`:tests`に1 ms、`:highlights`、`:story`、`:showcase`に35 msのフレーム待ち時間を使用します。単独パターンは`Goryokaku::Illumination::Player#play_pattern`で実行し、`PATTERNS`レジストリにある既定値を使用します。

| セットリスト | パターン数 | `wait_ms`の設定 |
| ------------ | ---------: | ----------------- |
| `:tests` | 1 | 1 ms |
| `:highlights` | 7 | 35 ms |
| `:story` | 15 | 35 ms |
| `:showcase` | 21 | 35 ms |

`:illumination`でセットリストまたは単独パターンを開始すると、PWMブザーの「きらきら星」も同時に始まります。`repeat: false`では曲を1回最後まで再生し、`repeat: true`では曲も繰り返します。`buzzer_volume: 0`を指定すると発音しません。

1回の再生が終わるか実行を中断すると、ブザーを停止して全LEDを消灯します。
