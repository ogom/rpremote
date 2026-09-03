# Time-driven processing with `tick`

[日本語](tick.ja.md)

This document explains how the run loop in `main.rb` calls `StatusLed::Presenter#tick(timestamp_ms)` to advance the time-dependent LED display one step at a time. See [Pub/Sub in the Oximeter sample](pub_sub.md) for state-change delivery through `publish` and the overall Pub/Sub design.

## `publish` versus `tick`

| Call | Meaning | Receiver method |
| --- | --- | --- |
| `dispatcher.publish(event, payload)` | Announces a state change such as finger detection or a beat. | `call(event, payload)` |
| `presenter.tick(timestamp_ms)` | Supplies the current time and advances LED animation by one step. | `tick(timestamp_ms)` |

`tick` does not read the sensor or create measurement events. `Dispatcher`, which only delivers events, has no `tick` method. Explicitly calling time-driven components keeps the event contract separate from scheduling.

## Call flow

[`main.rb`](../main.rb) processes the samples in the MAX30102 FIFO and then calls the presenter's `tick` once per main-loop iteration.

```ruby
while @clock.millis - started_at < @duration_ms
  available = @sensor.available_samples
  while available > 0
    sample = @sensor.read
    @processor.process_sample(
      red: sample[:red],
      ir: sample[:ir],
      timestamp_ms: @clock.millis
    )
    available -= 1
  end
  @presenter.tick(@clock.millis)
  @clock.wait_ms(@poll_interval_ms)
end
```

```text
Read FIFO samples
        │
        ▼
Measurement::Processor#process_sample
        │ publish an event when needed
        ▼
StatusLed::Presenter#call ──▶ store display state
        │
        ▼ explicit tick from the loop
StatusLed::Presenter#tick
        │
        ▼
StatusLed::Renderer#render ──▶ render when the frame interval has elapsed
```

## LED display use

`StatusLed::Presenter#call` updates this internal state from measurement events:

- Display mode: `:no_finger`, `:measuring`, or `:result`
- Estimated BPM and SpO2
- Timestamp of the most recently detected beat

`StatusLed::Presenter#tick` passes that state and `timestamp_ms` to [`StatusLed::Renderer#render`](../lib/oximeter/status_led/renderer.rb).

```ruby
def tick(timestamp_ms)
  @renderer.render(
    @mode,
    timestamp_ms,
    spo2: @spo2,
    bpm: @bpm,
    last_beat_at: @last_beat_at
  )
  self
end
```

The renderer returns without drawing until the interval for the current mode has elapsed.

| Mode | Frame interval | Behavior |
| --- | --- | --- |
| `:no_finger` | 120 ms | Moves a dim white point. |
| `:measuring` | 90 ms | Moves a blue point and its trail. |
| `:result` | 40 ms | Calculates the display position from BPM and the most recent beat time. |

This throttling allows the main loop to call `tick` about every 2 ms while limiting WS2812 transfers to required frames.

## Why `tick` is needed

If LEDs were rendered only when events arrived, animation would stop in a state such as waiting for a finger, where no new event is expected. A beat event by itself also cannot produce movement between that beat and the next one.

Storing “what happened” from events and calculating “what should be displayed now” from `tick` separates:

- The sensor sampling period
- The frequency of finger and beat events
- The LED animation frame interval

## Implementation rules

- `tick` must return quickly and must not call `sleep_ms` internally.
- One `tick` should advance one step rather than run a long loop or draw many frames in a batch.
- Use the caller-supplied `timestamp_ms` for elapsed-time decisions so components in the same loop share one time base.
- Exceptions in `tick` propagate to its caller.
- `tick` is synchronous; it is not a thread or interrupt.

## Current standalone-sample constraint

The standalone Oximeter loop processes every sample currently in the FIFO before calling the presenter's `tick`. A large backlog can therefore extend the LED update interval.

This follows from the processing order and does not identify the cause of any LED corruption. For concurrent operation, limit the number of sensor samples processed in one loop so that each component receives regular `tick` calls. The Daisenkofun common event loop applies this as `MAX_SAMPLES_PER_TICK`.
