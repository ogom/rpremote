# Biometric pulse and music

[日本語](biometric_pwm_music.ja.md)

The MAX30102 fingertip waveform is transformed into PWM melody and light on the Daisen Kofun model. The performance is generated from the current beat interval, SpO₂ movement, and pulse shape rather than replaying a recorded song.

> Heart rate and SpO₂ are presentation estimates. Do not use this work for diagnosis, treatment decisions, or safety monitoring.

## Values used by the performance

| Biometric input | Musical effect |
| --- | --- |
| Beat interval | Base pitch and rhythm |
| SpO₂ movement | Direction of pitch movement |
| Pulse width | Timbre through PWM duty |

At startup or when the pulse shape is not reliable, the program uses a safe default timbre. Removing the finger mutes the output and discards pending notes, the SpO₂ baseline, and any partial heartbeat signature.

### Beat interval and pitch

The base frequency is `256000 / interval_ms`, quantized to the nearest note in a C-major pentatonic range from 131 through 880 Hz. For example, an 800 ms beat interval produces 320 Hz before quantization and plays as 330 Hz. Intervals greater than 350 ms and less than 1,500 ms are used for the performance.

### SpO₂ and pitch direction

The first eight valid SpO₂ updates establish a personal baseline. A smoothed value more than 0.5 points above the baseline moves pitch upward; a value more than 0.5 points below moves it downward. A value that has not been updated for five seconds is not used for pitch direction.

This represents relative change during the performance, not a medical judgment about whether an SpO₂ value is good or bad.

### Pulse width and timbre

The duration of the low part of one pulse is normalized as `pulse_width_ratio` from 0 through 1 and mapped to 2–6% PWM duty:

```text
duty_percent = 2.0 + 4.0 × pulse_width_ratio
```

When pulse width is not available yet, the performance uses 3%. Duty changes the harmonic content even at the same pitch, allowing pulse shape to appear as a timbre difference.

## Musical styles

Select what listeners hear and how the LEDs move with `musical_style` in [`main.rb`](../main.rb).

| `musical_style` | Sound | Light |
| --- | --- | --- |
| `:pulse_translation` | A main note and half-beat response for each heartbeat | The outlines respond to each heartbeat |
| `:kofun_canon` | A three-note canon derived from each beat | The inner, middle, and outer moat outlines light in sequence |
| `:heartbeat_signature` | Seven canon beats followed by an eight-note phrase | The eight notes travel around the three moats |

### Pulse translation

Each heartbeat plays a main note followed by a response half a beat later. The beat interval sets the main note, and relative SpO₂ change moves the response one step down, keeps it level, or moves it one step up.

### Kofun canon

Each beat is divided into three parts for notes associated with the inner, middle, and outer moats. The notes are separated by zero, two, and four steps of the pentatonic scale.

When the interval becomes at least 40 ms shorter, travel moves from inside to outside; when it becomes at least 40 ms longer, travel reverses. Relative SpO₂ movement influences the base direction every four beats. The moats have no LEDs of their own, so the outlines bordering each moat light with the corresponding note.

### Heartbeat signature

The first seven beats use the canon. On the eighth, the latest eight beats form a short phrase. Each note reflects its beat interval, the speed change from the previous beat, SpO₂ change relative to the first beat, and pulse width. Notes last 45–90 ms and are placed within the eighth beat interval.

No randomness is used, so equal eight-beat input produces the same phrase. The next beat returns to the canon and starts a new group of eight; removing the finger discards a partial group.

## Volume

Set `Application::Config#buzzer_volume` from 0 through 100; `0` disables sound and the default is `3`. With an amplifier, start at the default and adjust amplifier gain while checking for hangs, distortion, or overheating.

The biometric 2–6% duty is multiplied by `buzzer_volume / 3` and capped at 50%. Actual loudness varies substantially by buzzer and amplifier, so verify it on hardware rather than relying on the number alone.

Connect PWM on GP18 to the amplifier input and use a common ground. Do not drive a speaker directly from a Pico GPIO. See [hardware and safety](hardware.md) for wiring details.

## Verification

Run `:combined` mode and confirm that:

- placing a finger makes sound and moat LEDs react to the heartbeat;
- `:heartbeat_signature` returns to the canon after its eight-note phrase;
- removing the finger mutes the output immediately; and
- the run ends with `event=done status=ok`.

In performance logs, `source=canon` identifies the normal canon and `source=heartbeat_signature` identifies a phrase derived from eight beats. `moat=inner|middle|outer` identifies the outline lit with the note, while `frequency_hz`, `duration_ms`, and `duty_percent` report pitch, note length, and PWM duty.

At shutdown, `event=verification status=ok` means that cue count and start delay met the runtime checks. `cues` is the number of performed cues, `max_delay_ms` is the largest delay from the scheduled start, and `signatures` is the number of generated heartbeat signatures. This log does not prove physical loudness or visual synchronization; observe the model as well.

See the [development workflow](development.md) for run and test commands.
