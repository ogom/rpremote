# frozen_string_literal: true

module Processing
  class Orientation
    RAD_PER_DEGREE = Math::PI / 180.0
    DEGREE_PER_RADIAN = 180.0 / Math::PI

    attr_reader :q0, :q1, :q2, :q3, :roll, :pitch, :yaw

    def initialize
      @q0 = 1.0
      @q1 = @q2 = @q3 = 0.0
      @roll = @pitch = @yaw = 0.0
    end

    def update(acceleration, gyroscope, dt)
      ax, ay, az = acceleration
      gx, gy, gz = gyroscope.map { |value| value * RAD_PER_DEGREE }
      norm = Math.sqrt(ax * ax + ay * ay + az * az)
      if norm > 0.01
        ax /= norm
        ay /= norm
        az /= norm
        vx = 2.0 * (@q1 * @q3 - @q0 * @q2)
        vy = 2.0 * (@q0 * @q1 + @q2 * @q3)
        vz = @q0 * @q0 - @q1 * @q1 - @q2 * @q2 + @q3 * @q3
        gx += 2.5 * (ay * vz - az * vy)
        gy += 2.5 * (az * vx - ax * vz)
        gz += 2.5 * (ax * vy - ay * vx)
      end
      integrate(gx, gy, gz, dt)
      update_euler_angles
    end

    private

    def integrate(gx, gy, gz, dt)
      q0 = @q0
      q1 = @q1
      q2 = @q2
      q3 = @q3
      @q0 += 0.5 * (-q1 * gx - q2 * gy - q3 * gz) * dt
      @q1 += 0.5 * (q0 * gx + q2 * gz - q3 * gy) * dt
      @q2 += 0.5 * (q0 * gy - q1 * gz + q3 * gx) * dt
      @q3 += 0.5 * (q0 * gz + q1 * gy - q2 * gx) * dt
      normalize
    end

    def normalize
      norm = Math.sqrt(@q0 * @q0 + @q1 * @q1 + @q2 * @q2 + @q3 * @q3)
      @q0 /= norm
      @q1 /= norm
      @q2 /= norm
      @q3 /= norm
    end

    def update_euler_angles
      @roll = Math.atan2(
        2.0 * (@q0 * @q1 + @q2 * @q3),
        1.0 - 2.0 * (@q1 * @q1 + @q2 * @q2)
      ) * DEGREE_PER_RADIAN
      pitch_sine = 2.0 * (@q0 * @q2 - @q3 * @q1)
      pitch_sine = 1.0 if pitch_sine > 1.0
      pitch_sine = -1.0 if pitch_sine < -1.0
      @pitch = Math.asin(pitch_sine) * DEGREE_PER_RADIAN
      @yaw = Math.atan2(
        2.0 * (@q0 * @q3 + @q1 * @q2),
        1.0 - 2.0 * (@q2 * @q2 + @q3 * @q3)
      ) * DEGREE_PER_RADIAN
    end
  end
end
