# frozen_string_literal: true

module Processing
  class GestureDetector
    attr_reader :posture

    def initialize
      @posture = 'LEVEL'
      @event_posture = 'LEVEL'
      @last_tap = -1000
      @tap_latched = false
      @last_sign = 0
      @crossings = 0
      @crossing_at = 0
      @shake = false
      @last_motion = 0
    end

    def update(now, roll, acceleration, gyroscope)
      update_posture(roll)
      event = detect_tap(now, acceleration)
      shake_event = detect_shake(now, gyroscope)
      event = shake_event unless shake_event == 'NONE'
      [event, @event_posture]
    end

    private

    def detect_tap(now, acceleration)
      magnitude = Math.sqrt(acceleration[0]**2 + acceleration[1]**2 + acceleration[2]**2)
      event = 'NONE'
      if magnitude >= 1.30 && !@tap_latched && now - @last_tap >= 60
        @tap_latched = true
        @last_tap = now
        @event_posture = @posture
        event = 'TAP'
      end
      @tap_latched = false if magnitude <= 1.04 || now - @last_tap >= 70
      event
    end

    def detect_shake(now, gyroscope)
      dominant = dominant_value(gyroscope)
      if dominant.abs >= 150.0
        update_crossings(now, dominant)
        if @crossings >= 2 && !@shake
          @shake = true
          @event_posture = @posture
          return 'SHAKE'
        end
      elsif @shake && now - @last_motion >= 120
        @shake = false
        return 'SHAKE_END'
      end
      'NONE'
    end

    def dominant_value(values)
      dominant = values[0]
      values[1..].each do |value|
        dominant = value if value.abs > dominant.abs
      end
      dominant
    end

    def update_crossings(now, dominant)
      sign = dominant.negative? ? -1 : 1
      if @last_sign != 0 && sign != @last_sign && now - @crossing_at <= 200
        @crossings += 1
      else
        @crossings = 0
      end
      @last_sign = sign
      @crossing_at = now
      @last_motion = now
    end

    def update_posture(roll)
      if @posture == 'RIGHT_TILT'
        @posture = 'LEVEL' if roll < 25.0
      elsif @posture == 'LEFT_TILT'
        @posture = 'LEVEL' if roll > -25.0
      elsif roll >= 30.0
        @posture = 'RIGHT_TILT'
      elsif roll <= -30.0
        @posture = 'LEFT_TILT'
      end
    end
  end
end
