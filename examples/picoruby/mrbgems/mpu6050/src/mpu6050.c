/*
 * MPU6050 mruby/c bindings.
 *
 * Ruby performs the I2C transaction and unit conversion. This extension
 * decodes one 14-byte sensor frame into signed 16-bit values.
 */

#include <stdint.h>
#include <mrubyc.h>

#define MPU6050_FRAME_SIZE 14
#define MPU6050_VALUE_COUNT 7

static int16_t
decode_i16_be(const uint8_t *bytes)
{
  return (int16_t)(((uint16_t)bytes[0] << 8) | bytes[1]);
}

static void
c__decode_frame(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 1) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
    return;
  }

  mrbc_value frame = v[1];
  if (frame.tt != MRBC_TT_STRING) {
    mrbc_raise(vm, MRBC_CLASS(TypeError), "frame must be a String");
    return;
  }
  if (frame.string->size != MPU6050_FRAME_SIZE) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "frame must contain exactly 14 bytes");
    return;
  }

  const uint8_t *bytes = frame.string->data;
  mrbc_value result = mrbc_array_new(vm, MPU6050_VALUE_COUNT);

  for (int i = 0; i < MPU6050_VALUE_COUNT; i++) {
    mrbc_value value = mrbc_integer_value(decode_i16_be(bytes + (i * 2)));
    mrbc_array_push(&result, &value);
  }

  SET_RETURN(result);
}

void
mrbc_mpu6050_init(mrbc_vm *vm)
{
  mrbc_class *class_MPU6050 = mrbc_define_class(vm, "MPU6050", mrbc_class_object);
  mrbc_define_method(vm, class_MPU6050, "_decode_frame", c__decode_frame);
}
