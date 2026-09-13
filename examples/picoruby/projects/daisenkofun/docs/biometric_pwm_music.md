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

## Musical styles

### Pulse translation

Each heartbeat plays a main note followed by a response half a beat later. The response moves down, stays level, or moves up with the SpO₂ trend.

### Kofun canon

One heartbeat produces three notes that travel across the inner, middle, and outer moats. The direction responds to whether the beat becomes faster or slower, and each moat-outline LED lights with its note.

### Heartbeat signature

The first seven beats use the canon. On the eighth, the latest eight beats form a short eight-note phrase. Equal input produces the same phrase, and the next beat returns to the canon.

## Volume

Set `Application::Config#buzzer_volume` from 0 through 100; `0` disables sound and the default is `3`. With an amplifier, start at the default and adjust amplifier gain while checking for hangs, distortion, or overheating.

Connect PWM on GP18 to the amplifier input and use a common ground. Do not drive a speaker directly from a Pico GPIO. See [hardware and safety](hardware.md) for wiring details.

## Verification

Run `:combined` mode and confirm that:

- placing a finger makes sound and moat LEDs react to the heartbeat;
- `:heartbeat_signature` returns to the canon after its eight-note phrase;
- removing the finger mutes the output immediately; and
- the run ends with `event=done status=ok`.

See the [development workflow](development.md) for run and test commands.
