# frozen_string_literal: true

module Daisenkofun
  module Illumination
    class Player
      def initialize(device: nil, strip: nil, logger: nil)
        raise ArgumentError, "device and strip are mutually exclusive" if device && strip

        @device = device || Device.new(strip: strip)
        @logger = logger
      end

      def play_setlist(setlist_name, repeat: false)
        play_entries(Setlist.resolve(setlist_name), repeat)
      end

      def play_pattern(pattern_key, repeat: false)
        entry = Setlist.entry_for(pattern_key)
        raise ArgumentError, "pattern_key must name a registered pattern" unless entry

        play_entries([entry], repeat)
      end

      def stop
        return self unless @device.open?

        begin
          @device.close
        ensure
          log("DAISENKOFUN mode=illumination event=led_off")
        end
        self
      end

      private

      def play_entries(entries, repeat)
        unless repeat == true || repeat == false
          raise ArgumentError, "repeat must be true or false"
        end

        @device.open
        begin
          loop do
            call_patterns(@device.strip, entries)
            break unless repeat
          end
        ensure
          stop
        end
      end

      def call_patterns(strip, entries)
        index = 0
        while index < entries.length
          entry = entries[index]
          key = Setlist.key(entry)
          wait_ms = Setlist.wait_ms(entry)
          loops = Setlist.loops(entry)
          log("DAISENKOFUN mode=illumination event=pattern index=#{index + 1}/#{entries.length} key=#{key} wait_ms=#{wait_ms} loops=#{loops}")
          @device.clear
          call_pattern(strip, key, wait_ms, loops)
          index += 1
        end
      end

      def call_pattern(strip, key, wait_ms, loops)
        klass = Setlist.pattern_class(key)
        klass.new(Display.new(strip), wait_ms, loops).call
      end

      def log(message)
        if @logger
          @logger.puts(message)
        else
          puts message
        end
      end
    end
  end
end
