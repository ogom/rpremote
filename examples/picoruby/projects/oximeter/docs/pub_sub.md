# Pub/Sub in the Oximeter sample

[日本語](pub_sub.ja.md)

This document explains the Pub/Sub implementation that separates measurement processing from display processing, and why that separation is useful. See [time-driven processing with `tick`](tick.md) for display updates driven by elapsed time.

## Structure

Events flow synchronously in this order from a sensor sample to LED display state:

```text
MAX30102
    │ red / ir
    ▼
Measurement::Processor [Publisher]
    │ publish(event, payload)
    ▼
Dispatcher
    │ call(event, payload)
    ▼
StatusLed::Presenter [Subscriber]
    └─ holds the mode, BPM, SpO2, and most recent beat time
```

| Role | Implementation | Responsibility |
| --- | --- | --- |
| Publisher | `Measurement::Processor` | Determines finger, beat, and measurement-result state from sensor values and publishes events. |
| Dispatcher | `Dispatcher` | Delivers published events synchronously to registered subscribers. |
| Subscriber | `StatusLed::Presenter` | Translates events into LED display state. |

Receiving an event only updates display state. See [time-driven processing with `tick`](tick.md) for the actual rendering of the eight status LEDs.

## Event definitions

Event names are constants in `Oximeter::Measurement::Events` in [`lib/oximeter/measurement/events.rb`](../lib/oximeter/measurement/events.rb).

| Event | Published when | Main payload fields |
| --- | --- | --- |
| `finger_detected` | The IR value rises above the finger-detection threshold | `timestamp_ms`, `ir` |
| `finger_removed` | The IR value falls below the finger-removal threshold | `timestamp_ms`, `ir` |
| `beat` | A beat interval inside the accepted range is detected | `timestamp_ms`, `red`, `ir`, `interval_ms`, `bpm` |
| `measurement_updated` | Heart-rate and SpO2 estimates are updated | `timestamp_ms`, `red`, `ir`, `bpm`, `spo2` |
| `measurement_completed` | The required number of beats is first collected | `timestamp_ms`, `red`, `ir`, `bpm`, `spo2` |

Event names describe facts that have already occurred rather than commands. Publishing `finger_detected` instead of `turn_led_blue` keeps display decisions out of the measurement logic.

## Registering a subscriber

[`main.rb`](../main.rb) creates the dispatcher, registers the presenter, and passes the same dispatcher to the processor.

```ruby
dispatcher = Oximeter::Dispatcher.new
presenter = Oximeter::StatusLed::Presenter.new(renderer)
dispatcher.subscribe(presenter)
processor = Oximeter::Measurement::Processor.new(dispatcher: dispatcher)
```

`subscribe` appends the object and returns `self`. If multiple subscribers are registered, they are called in registration order.

## Publishing and delivery

`Measurement::Processor` calls `publish` where a state transition occurs. Finger detection is published like this:

```ruby
@dispatcher.publish(Events::FINGER_DETECTED, {
  timestamp_ms: timestamp_ms,
  ir: ir
})
```

[`Dispatcher#publish`](../lib/oximeter/dispatcher.rb) visits subscribers in registration order and immediately calls each `call(event, payload)` method.

```ruby
def publish(event, payload)
  index = 0
  while index < @subscribers.length
    @subscribers[index].call(event, payload)
    index += 1
  end
  self
end
```

This is synchronous delivery without threads, an event queue, or delayed dispatch. `publish` returns only after every subscriber completes.

## Subscriber processing

[`StatusLed::Presenter`](../lib/oximeter/status_led/presenter.rb) receives events through `call` and updates its display mode, BPM, SpO2, and most recent beat time.

```ruby
def call(event, payload)
  case event
  when Measurement::Events::FINGER_DETECTED
    reset_measurement
    @mode = States::MEASURING
  when Measurement::Events::BEAT
    @bpm = payload[:bpm]
    @last_beat_at = payload[:timestamp_ms]
  # ...
  end
  self
end
```

`call` stores the state needed by the display but does not write to the WS2812 LEDs. Rendering happens from `tick`, separating the sensor-event rate from the LED frame interval.

## Why Pub/Sub is used

### Keep the measurement algorithm independent of the display

If `Measurement::Processor` directly called `StatusLed::Renderer`, the measurement algorithm would depend on eight WS2812 LEDs, their colors, and their animation. With Pub/Sub, the processor publishes measurement facts only, so measurement processing also works without LEDs.

### Localize changes

Changing display colors or animation does not affect the measurement algorithm. Conversely, beat detection or SpO2 estimation can change without modifying the subscriber as long as the event and payload contract remains stable.

### Make unit testing easier

A subscriber that only records events can verify event order without hardware. The display side can also be tested independently by passing arbitrary events to `call`.

## Adding a subscriber

A subscriber implements `call(event, payload)`.

```ruby
class BeatLogger
  def call(event, payload)
    return self unless event == Oximeter::Measurement::Events::BEAT

    puts "BEAT,bpm=#{payload[:bpm]}"
    self
  end
end

dispatcher.subscribe(BeatLogger.new)
```

A component that also needs time-driven updates can implement `tick(timestamp_ms)` and be called explicitly by the application loop. The dispatcher only delivers events; it does not advance time.

## Implementation constraints

- Delivery is synchronous. A subscriber that does not return quickly blocks sensor reads and later subscribers.
- A subscriber exception propagates from `publish`, and later subscribers are not called.
- The implementation has no event retention, retry, priority, or `unsubscribe`.
- Every subscriber receives the same payload object. Subscribers should treat it as read-only.
- Update the publisher and every subscriber as one contract when changing an event name or payload.
