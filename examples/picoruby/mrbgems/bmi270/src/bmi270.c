#include <stdint.h>
#include <mrubyc.h>
#include "bmi270_config.h"

static int16_t decode_i16_le(const uint8_t *p) {
  return (int16_t)(((uint16_t)p[1] << 8) | p[0]);
}

static void c_decode_frame(mrbc_vm *vm, mrbc_value *v, int argc) {
  if (argc != 1) { mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments"); return; }
  if (v[1].tt != MRBC_TT_STRING) { mrbc_raise(vm, MRBC_CLASS(TypeError), "frame must be a String"); return; }
  if (v[1].string->size != 12) { mrbc_raise(vm, MRBC_CLASS(ArgumentError), "frame must contain exactly 12 bytes"); return; }
  const uint8_t *p = v[1].string->data;
  mrbc_value result = mrbc_array_new(vm, 6);
  for (int i = 0; i < 6; i++) {
    mrbc_value n = mrbc_integer_value(decode_i16_le(p + i * 2));
    mrbc_array_push(&result, &n);
  }
  SET_RETURN(result);
}

static void c_default_configuration_chunk(mrbc_vm *vm, mrbc_value *v, int argc) {
  if (argc != 2) { mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments"); return; }
  if (v[1].tt != MRBC_TT_INTEGER || v[2].tt != MRBC_TT_INTEGER) {
    mrbc_raise(vm, MRBC_CLASS(TypeError), "offset and length must be Integers");
    return;
  }
  mrbc_int_t offset = mrbc_integer(v[1]);
  mrbc_int_t length = mrbc_integer(v[2]);
  if (offset < 0 || length < 0 || BMI270_CONFIG_SIZE < (uint32_t)offset + (uint32_t)length) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "configuration chunk is out of range");
    return;
  }
  mrbc_value chunk = mrbc_string_new(vm, (const char *)&bmi270_config_file[offset], length);
  SET_RETURN(chunk);
}

void mrbc_bmi270_init(mrbc_vm *vm) {
  mrbc_class *klass = mrbc_define_class(vm, "BMI270", mrbc_class_object);
  mrbc_define_method(vm, klass, "_decode_frame", c_decode_frame);
  mrbc_define_method(vm, klass, "_default_configuration_chunk", c_default_configuration_chunk);
}
