# Pub/Sub design in the Oximeter sample

[日本語](pub_sub.ja.md)

The Oximeter separates measurement interpretation from LED presentation with Pub/Sub. This guide explains why that boundary exists and what must remain true when changing it. See [time-driven processing with `tick`](tick.md) for elapsed-time rendering.

## Structure

```text
MAX30102
    │ red / ir
    ▼
Measurement::Processor ── publish ──▶ Dispatcher
                                           │ synchronous delivery
                                           ▼
                                  StatusLed::Presenter
                                           │ display state
                                           ▼
                                  StatusLed::Renderer
```

| Role | Implementation | Responsibility |
| ---- | -------------- | -------------- |
| Publisher | `Measurement::Processor` | Publishes measurement facts about fingers, beats, and estimates |
| Dispatcher | `Dispatcher` | Delivers events synchronously to registered subscribers |
| Subscriber | `StatusLed::Presenter` | Translates measurement events into display state |
| Renderer | `StatusLed::Renderer` | Draws eight LEDs from the current time and display state |

The processor knows nothing about LED colors or animation, and the presenter does not read the sensor. This boundary permits measurement without LEDs and display changes without changing the measurement algorithm.

## Measurement events

Event names describe facts that have occurred, not commands. Publishing `finger_detected` instead of `turn_led_blue` keeps the color decision in the display layer.

| Event | Meaning |
| ----- | ------- |
| `finger_detected` | A finger arrived and a new measurement started |
| `finger_removed` | The finger left and measurement state was reset |
| `beat` | A valid beat interval was detected |
| `measurement_updated` | Heart-rate and SpO2 estimates were updated |
| `measurement_completed` | The required beat count was reached for the first time |

[`measurement/events.rb`](../lib/oximeter/measurement/events.rb) is the authoritative list of names. A payload contains only the timestamp and measurement values needed to interpret that fact.

## Why delivery is synchronous

There are few events and subscribers, so delivery uses no threads or queue. This makes execution order visible and keeps memory use and cleanup simple on PicoRuby.

The tradeoff is that a slow subscriber blocks sensor reads and later subscribers. A subscriber exception returns to the publisher, and later subscribers are not called. There is no retention, retry, priority, or unsubscribe operation.

Subscribers therefore must:

- return quickly from `call(event, payload)`;
- treat payloads as read-only;
- avoid completing a long animation inside `call`; and
- update publishers and subscribers together when an event name or payload changes.

## Separating events from time

The presenter's `call` stores “what happened” as display state. The main loop advances WS2812 rendering through `tick(timestamp_ms)`.

This separation keeps LEDs moving while no event occurs, such as while waiting for a finger. It also allows sensor sampling, measurement-event frequency, and LED frame timing to be adjusted independently.
