# Time-driven processing with `tick`

[日本語](tick.ja.md)

Measurement events report “what happened.” LED animation also needs to update “what should be visible now” while no event occurs. `StatusLed::Presenter#tick(timestamp_ms)` provides that time-driven step.

## Difference from `publish`

| Call | Role |
| ---- | ---- |
| `dispatcher.publish(event, payload)` | Synchronously announces a state change such as finger detection or a beat |
| `presenter.tick(timestamp_ms)` | Supplies the current time and advances at most one display frame when needed |

`tick` does not read the sensor or generate measurement events. The dispatcher does not advance time. See [Pub/Sub design](pub_sub.md) for event delivery.

## Call flow

```text
Read the MAX30102 FIFO
        │
        ▼
Measurement::Processor#process_sample
        │ publish when needed
        ▼
StatusLed::Presenter#call ──▶ store display state
        │
        ▼ tick from the main loop
StatusLed::Presenter#tick
        │
        ▼
StatusLed::Renderer#render ──▶ transfer only when the frame interval is due
```

After processing FIFO samples, the main loop gives the presenter the same board time. The presenter passes display mode, BPM, SpO2, and the last beat time to the renderer, which decides whether and where to draw.

## Display intervals

| State | Interval | Display |
| ----- | -------: | ------- |
| Waiting for a finger | 120 ms | Dim white point |
| Measuring | 90 ms | Blue point with a green trail |
| Result | 40 ms | Green or red point synchronized to BPM and the last beat |

The main loop can call `tick` about every 2 ms, but the renderer does not resend WS2812 data until a frame is due. This limits LED transfers without stopping measurement.

## Implementation boundaries

- `tick` returns quickly and does not call `sleep_ms`.
- One call draws at most the one frame currently needed.
- Elapsed-time decisions use the caller's `timestamp_ms`.
- Failures return to the caller, whose cleanup stops the sensor and clears the LEDs.
- `tick` is synchronous; it is not a thread or interrupt.

## Standalone-sample constraint

The current main loop processes every sample already in the FIFO before calling `tick`. A large backlog can therefore delay LED updates.

When extending the design for concurrent work, limit samples processed per loop so every component receives regular ticks. This is a consequence of processing order, not a diagnosis of any particular LED failure.
