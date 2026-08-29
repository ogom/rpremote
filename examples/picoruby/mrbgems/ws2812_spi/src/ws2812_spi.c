/* WS2812 SPI waveform encoder for mruby/c. */

#include <stdint.h>
#include <string.h>
#include <mrubyc.h>

#define WS2812_SPI_RESET_BYTES 80
#define WS2812_SPI_BYTES_PER_PIXEL 24
#define WS2812_SPI_ZERO_BYTE 0x60
#define WS2812_SPI_ONE_BYTE 0x7c

static void
encode_color(uint8_t **output, uint8_t color)
{
  for (int bit = 7; bit >= 0; bit--) {
    *(*output)++ = (color & (1U << bit)) ?
      WS2812_SPI_ONE_BYTE : WS2812_SPI_ZERO_BYTE;
  }
}

static void
encode_pixel(uint8_t *output, uint32_t rgb)
{
  uint8_t red = (uint8_t)(rgb >> 16);
  uint8_t green = (uint8_t)(rgb >> 8);
  uint8_t blue = (uint8_t)rgb;
  encode_color(&output, green);
  encode_color(&output, red);
  encode_color(&output, blue);
}

static void
c_encode(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 1 && argc != 2) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "wrong number of arguments");
    return;
  }
  if (v[1].tt != MRBC_TT_ARRAY) {
    mrbc_raise(vm, MRBC_CLASS(TypeError), "pixels must be an Array");
    return;
  }

  mrbc_int_t count = v[1].array->n_stored;
  if (count <= 0) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "pixels must not be empty");
    return;
  }

  int length = (WS2812_SPI_RESET_BYTES * 2) +
    (count * WS2812_SPI_BYTES_PER_PIXEL);
  mrbc_value frame;
  if (argc == 2) {
    if (v[2].tt != MRBC_TT_STRING || v[2].string->size != length) {
      mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid frame buffer");
      return;
    }
    frame = v[2];
  } else {
    frame = mrbc_string_new(vm, NULL, length);
    if (frame.tt != MRBC_TT_STRING) {
      mrbc_raise(vm, MRBC_CLASS(NoMemoryError), "frame allocation failed");
      return;
    }
  }
  uint8_t *bytes = frame.string->data;
  memset(bytes, 0, length);
  uint8_t *output = bytes + WS2812_SPI_RESET_BYTES;

  for (mrbc_int_t index = 0; index < count; index++) {
    mrbc_value pixel = mrbc_array_get(&v[1], index);
    if (pixel.tt != MRBC_TT_INTEGER) {
      if (argc == 1) {
        mrbc_decref(&frame);
      }
      mrbc_raise(vm, MRBC_CLASS(TypeError), "pixel must be an Integer");
      return;
    }

    encode_pixel(output, (uint32_t)mrbc_integer(pixel));
    output += WS2812_SPI_BYTES_PER_PIXEL;
  }

  if (argc == 1) {
    SET_RETURN(frame);
  } else {
    SET_NIL_RETURN();
  }
}

static void
c_encode_pixel(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 3 || v[1].tt != MRBC_TT_STRING ||
      v[2].tt != MRBC_TT_INTEGER || v[3].tt != MRBC_TT_INTEGER) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid pixel arguments");
    return;
  }

  int frame_size = v[1].string->size;
  if (frame_size < WS2812_SPI_RESET_BYTES * 2 ||
      (frame_size - WS2812_SPI_RESET_BYTES * 2) % WS2812_SPI_BYTES_PER_PIXEL != 0) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid frame buffer");
    return;
  }

  mrbc_int_t index = mrbc_integer(v[2]);
  int pixel_count = (frame_size - WS2812_SPI_RESET_BYTES * 2) /
    WS2812_SPI_BYTES_PER_PIXEL;
  if (index < 0 || index >= pixel_count) {
    mrbc_raise(vm, MRBC_CLASS(IndexError), "pixel index out of range");
    return;
  }

  int offset = WS2812_SPI_RESET_BYTES +
    ((int)index * WS2812_SPI_BYTES_PER_PIXEL);
  encode_pixel(v[1].string->data + offset, (uint32_t)mrbc_integer(v[3]));
  SET_NIL_RETURN();
}

void
mrbc_ws2812_spi_init(mrbc_vm *vm)
{
  mrbc_class *klass = mrbc_define_class(vm, "WS2812SPI", mrbc_class_object);
  mrbc_define_method(vm, klass, "_encode", c_encode);
  mrbc_define_method(vm, klass, "_encode_pixel", c_encode_pixel);
}
