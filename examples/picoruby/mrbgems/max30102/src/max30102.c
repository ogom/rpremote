/* MAX30102 mruby/c FIFO decoder. */

#include <stdint.h>
#include <mrubyc.h>

#define MAX30102_FRAME_SIZE 6
#define MAX30102_SAMPLE_MASK 0x3ffffUL

static uint32_t
decode_u18_be(const uint8_t *bytes)
{
  return ((((uint32_t)bytes[0] << 16) |
           ((uint32_t)bytes[1] << 8) |
           bytes[2])) & MAX30102_SAMPLE_MASK;
}

static void
c_decode_frame(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 1) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
    return;
  }
  if (v[1].tt != MRBC_TT_STRING) {
    mrbc_raise(vm, MRBC_CLASS(TypeError), "frame must be a String");
    return;
  }
  if (v[1].string->size != MAX30102_FRAME_SIZE) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "frame must contain exactly 6 bytes");
    return;
  }

  const uint8_t *bytes = v[1].string->data;
  mrbc_value result = mrbc_array_new(vm, 2);
  mrbc_value red = mrbc_integer_value(decode_u18_be(bytes));
  mrbc_value ir = mrbc_integer_value(decode_u18_be(bytes + 3));
  mrbc_array_push(&result, &red);
  mrbc_array_push(&result, &ir);
  SET_RETURN(result);
}

void
mrbc_max30102_init(mrbc_vm *vm)
{
  mrbc_class *klass = mrbc_define_class(vm, "MAX30102", mrbc_class_object);
  mrbc_define_method(vm, klass, "_decode_frame", c_decode_frame);
}
