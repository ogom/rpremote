# Development

[日本語](development.ja.md)

Work from the repository root and read [Hardware and safety](hardware.md) before wiring.

Use `rpremote exec` for an already-built individual pattern:

```sh
rpremote exec 'require "goryokaku-illumination"; Goryokaku::Illumination::Player.new.play_pattern(:warm_white)' --timeout 120
```

Use `rpremote run examples/picoruby/projects/goryokaku/main.rb --timeout 120` to verify configuration, DFU confirmation, composition, and cleanup. A successful run logs `event=done status=ok`; an error logs `status=error` after cleanup and is re-raised.

After changing an mrbgem or `Mrbgems`, run:

```sh
rpremote mrbgems check
rpremote mrbgems lock
rpremote build
rpremote flash
```

For release verification, run all 21 patterns and four setlists. Illumination playback must start the LEDs and “Twinkle, Twinkle, Little Star” together, complete the tune once by default, and return PWM duty to zero on completion or failure. In combined mode, confirm that Y-up touches alternate the candidate with a red illumination or blue tambourine ravelin indicator, that the indicator persists while moving to Z-up, and that only a Z-up touch confirms it. After confirming tambourine, return to Y-up with group 5 at the top: smooth Z-axis shake reversals must scan a multicolor trail from group 5, and a sharp Z-axis strike must synchronize a “shan-shan” shimmer with a fireworks-style burst from the star center through the ravelin to the outer ring. Illumination mode must preserve orientation display and configured setlist playback while motion remains silent. Musical mode must provide the same synchronized performance without touch selection. Confirm that leaving Y-up or stopping clears the LEDs and returns PWM duty to zero. Use an external high-current 5 V LED supply with common ground and verify maximum brightness/current on hardware.
