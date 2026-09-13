# frozen_string_literal: true

module Goryokaku
  module Illumination
    class Player
      def initialize(device: nil, strip: nil, pin: Config::LED_PIN, num: LedLayout::LED_COUNT, logger: nil, soundtrack: nil)
        raise ArgumentError, "device and strip are mutually exclusive" if device && strip
        @device = device || Device.new(strip: strip, pin: pin, num: num)
        @logger = logger
        @soundtrack = soundtrack
      end

      def play_setlist(name, repeat: false)
        play_entries(Setlist.resolve(name), repeat)
      end

      def play_pattern(key, repeat: false)
        entry = Setlist.entry_for(key)
        raise ArgumentError, "pattern_key must name a registered pattern" unless entry
        play_entries([entry], repeat)
      end

      def stop
        @soundtrack.stop if @soundtrack
        return self unless @device.open?
        begin
          @device.close
        ensure
          log("GORYOKAKU mode=illumination event=led_off")
        end
        self
      end

      private

      def play_entries(entries, repeat)
        raise ArgumentError, "repeat must be true or false" unless repeat == true || repeat == false
        @device.open
        @soundtrack.start(repeat: repeat) if @soundtrack
        begin
          loop do
            call_patterns(entries)
            break unless repeat
          end
          @soundtrack.join if @soundtrack && !repeat
        ensure
          stop
        end
      end

      def call_patterns(entries)
        index = 0
        while index < entries.length
          entry = entries[index]
          key = Setlist.key(entry)
          wait_ms = Setlist.wait_ms(entry)
          loops = Setlist.loops(entry)
          log("GORYOKAKU mode=illumination event=pattern index=#{index + 1}/#{entries.length} key=#{key} wait_ms=#{wait_ms} loops=#{loops}")
          @device.clear
          display = Display.new(@device.strip, frame_waiter: @soundtrack)
          Setlist.pattern_class(key).new(display, wait_ms, loops).call
          index += 1
        end
      end

      def log(message)
        @logger ? @logger.puts(message) : puts(message)
      end
    end
  end
end
