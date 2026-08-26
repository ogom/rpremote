/* HC-SR04 timing-sensitive measurement routines for mruby/c. */

#include <limits.h>
#include <stdint.h>
#include <mrubyc.h>
#include <gpio.h>
#include <machine.h>

#define INITIAL_SETTLE_US 20000U
#define TRIGGER_SETTLE_US 2U
#define TRIGGER_PULSE_US 10U
#define BASE_SOUND_SPEED_MPS 331.5
#define SOUND_SPEED_TEMPERATURE_COEFFICIENT 0.6

static mrbc_class *timeout_error_class;

static mrbc_value
get_ivar(mrbc_value *object, const char *name)
{
  return mrbc_instance_getiv(object, mrbc_str_to_symid(name));
}

static void
delay_us(uint64_t microseconds)
{
  while (microseconds > UINT32_MAX) {
    Machine_busy_wait_us(UINT32_MAX);
    microseconds -= UINT32_MAX;
  }
  if (microseconds > 0) {
    Machine_busy_wait_us((uint32_t)microseconds);
  }
}

static int
gpio_pin(mrbc_vm *vm, mrbc_value *sensor, const char *name, uint8_t *pin)
{
  mrbc_value gpio = get_ivar(sensor, name);
  if (gpio.tt != MRBC_TT_OBJECT) {
    mrbc_decref(&gpio);
    mrbc_raise(vm, MRBC_CLASS(TypeError), "trigger and echo must be GPIO objects");
    return 0;
  }

  mrbc_value pin_value = get_ivar(&gpio, "pin");
  if (pin_value.tt != MRBC_TT_INTEGER ||
      mrbc_integer(pin_value) < 0 || mrbc_integer(pin_value) > UINT8_MAX) {
    mrbc_decref(&pin_value);
    mrbc_decref(&gpio);
    mrbc_raise(vm, MRBC_CLASS(TypeError), "GPIO pin must be a non-negative Integer");
    return 0;
  }

  *pin = (uint8_t)mrbc_integer(pin_value);
  mrbc_decref(&pin_value);
  mrbc_decref(&gpio);
  return 1;
}

static int
read_positive_integer_ivar(mrbc_vm *vm, mrbc_value *sensor,
                           const char *name, uint64_t *value)
{
  mrbc_value option = get_ivar(sensor, name);
  if (option.tt != MRBC_TT_INTEGER || mrbc_integer(option) <= 0) {
    mrbc_decref(&option);
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid HC-SR04 timing option");
    return 0;
  }
  *value = (uint64_t)mrbc_integer(option);
  mrbc_decref(&option);
  return 1;
}

static int
wait_for_echo(mrbc_vm *vm, uint8_t pin, int level, uint64_t timeout_us,
              uint64_t *detected_at)
{
  uint64_t started_at = Machine_uptime_us();
  for (;;) {
    uint64_t now = Machine_uptime_us();
    if ((GPIO_read(pin) != 0) == (level != 0)) {
      *detected_at = now;
      return 1;
    }
    if (now - started_at >= timeout_us) {
      mrbc_raise(vm, timeout_error_class,
                 level ? "timed out waiting for ECHO to rise"
                       : "timed out waiting for ECHO to fall");
      return 0;
    }
  }
}

static void
c_pulse_width_us(mrbc_vm *vm, mrbc_value *v, int argc)
{
  uint8_t trigger_pin;
  uint8_t echo_pin;
  uint64_t timeout_us;

  if (argc != 0) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
    return;
  }
  if (!gpio_pin(vm, &v[0], "trigger", &trigger_pin) ||
      !gpio_pin(vm, &v[0], "echo", &echo_pin) ||
      !read_positive_integer_ivar(vm, &v[0], "timeout_us", &timeout_us)) {
    return;
  }

  mrbc_value initializing_at = get_ivar(&v[0], "initializing_at");
  if (initializing_at.tt == MRBC_TT_INTEGER) {
    uint64_t elapsed = Machine_uptime_us() -
      (uint64_t)mrbc_integer(initializing_at);
    if (elapsed < INITIAL_SETTLE_US) {
      delay_us(INITIAL_SETTLE_US - elapsed);
    }
    mrbc_value nil_value = mrbc_nil_value();
    mrbc_instance_setiv(&v[0], mrbc_str_to_symid("initializing_at"), &nil_value);
  }
  mrbc_decref(&initializing_at);

  mrbc_value last_trigger_at = get_ivar(&v[0], "last_trigger_at");
  if (last_trigger_at.tt == MRBC_TT_INTEGER) {
    mrbc_value interval = get_ivar(&v[0], "measurement_interval_us");
    uint64_t interval_us = (uint64_t)mrbc_integer(interval);
    uint64_t elapsed = Machine_uptime_us() -
      (uint64_t)mrbc_integer(last_trigger_at);
    if (elapsed < interval_us) {
      delay_us(interval_us - elapsed);
    }
    mrbc_decref(&interval);
  }
  mrbc_decref(&last_trigger_at);

  GPIO_write(trigger_pin, 0);
  Machine_busy_wait_us(TRIGGER_SETTLE_US);
  GPIO_write(trigger_pin, 1);
  Machine_busy_wait_us(TRIGGER_PULSE_US);
  GPIO_write(trigger_pin, 0);

  mrbc_value triggered_at = mrbc_integer_value((mrbc_int_t)Machine_uptime_us());
  mrbc_instance_setiv(&v[0], mrbc_str_to_symid("last_trigger_at"), &triggered_at);

  uint64_t rising_at;
  uint64_t falling_at;
  if (!wait_for_echo(vm, echo_pin, 1, timeout_us, &rising_at) ||
      !wait_for_echo(vm, echo_pin, 0, timeout_us, &falling_at)) {
    return;
  }

  SET_INT_RETURN((mrbc_int_t)(falling_at - rising_at));
}

static void
c_calculate_distance_cm(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 1 || v[1].tt != MRBC_TT_INTEGER || mrbc_integer(v[1]) < 0) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError),
               "pulse_width_us must be a non-negative Integer");
    return;
  }

  mrbc_value temperature = get_ivar(&v[0], "temperature_c");
  mrbc_float_t temperature_c;
  if (temperature.tt == MRBC_TT_FLOAT) {
    temperature_c = temperature.d;
  } else if (temperature.tt == MRBC_TT_INTEGER) {
    temperature_c = (mrbc_float_t)mrbc_integer(temperature);
  } else {
    mrbc_decref(&temperature);
    mrbc_raise(vm, MRBC_CLASS(TypeError),
               "temperature_c must be an Integer or Float");
    return;
  }

  mrbc_float_t sound_speed_mps = BASE_SOUND_SPEED_MPS +
    SOUND_SPEED_TEMPERATURE_COEFFICIENT * temperature_c;
  mrbc_float_t centimeters =
    (mrbc_float_t)mrbc_integer(v[1]) * sound_speed_mps / 20000.0;
  mrbc_decref(&temperature);
  SET_FLOAT_RETURN(centimeters);
}

void
mrbc_hcsr04_temp_init(mrbc_vm *vm)
{
  mrbc_class *klass = mrbc_define_class(vm, "HCSR04Temp", mrbc_class_object);
  timeout_error_class = mrbc_define_class_under(
    vm, klass, "TimeoutError", MRBC_CLASS(StandardError));
  mrbc_define_method(vm, klass, "_pulse_width_us", c_pulse_width_us);
  mrbc_define_method(vm, klass, "_calculate_distance_cm", c_calculate_distance_cm);
}
