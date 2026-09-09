/* Bulk WS2812 frame transfer for the Daisen Kofun mruby/c display. */

#include <stdint.h>
#include <mrubyc.h>

static void
c_clear_pixels(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 1 || v[1].tt != MRBC_TT_ARRAY) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid pixel buffer");
    return;
  }

  int count = v[1].array->n_stored;
  for (int index = 0; index < count; index++) {
    v[1].array->data[index] = mrbc_integer_value(0);
  }
  SET_NIL_RETURN();
}

static void
c_fill_indices(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 3 || v[1].tt != MRBC_TT_ARRAY ||
      v[2].tt != MRBC_TT_ARRAY || v[3].tt != MRBC_TT_INTEGER) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid indexed fill");
    return;
  }

  int pixel_count = v[1].array->n_stored;
  int count = v[2].array->n_stored;
  mrbc_value color = mrbc_integer_value(mrbc_integer(v[3]));
  for (int index = 0; index < count; index++) {
    mrbc_value position = v[2].array->data[index];
    if (position.tt != MRBC_TT_INTEGER) {
      mrbc_raise(vm, MRBC_CLASS(TypeError), "pixel index must be an Integer");
      return;
    }
    int offset = mrbc_integer(position);
    if (offset < 0 || offset >= pixel_count) {
      mrbc_raise(vm, MRBC_CLASS(IndexError), "pixel index out of range");
      return;
    }
    v[1].array->data[offset] = color;
  }
  SET_NIL_RETURN();
}

static void
c_write_pixels(mrbc_vm *vm, mrbc_value *v, int argc)
{
  if (argc != 2 || v[2].tt != MRBC_TT_ARRAY) {
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "invalid pixel buffer");
    return;
  }

  mrbc_value buffer = mrbc_instance_getiv(&v[1], mrbc_str_to_symid("buffer"));
  if (buffer.tt != MRBC_TT_ARRAY ||
      buffer.array->n_stored != v[2].array->n_stored * 3) {
    mrbc_decref(&buffer);
    mrbc_raise(vm, MRBC_CLASS(ArgumentError), "pixel buffer size mismatch");
    return;
  }

  int count = v[2].array->n_stored;
  for (int index = 0; index < count; index++) {
    mrbc_value pixel = v[2].array->data[index];
    if (pixel.tt != MRBC_TT_INTEGER) {
      mrbc_decref(&buffer);
      mrbc_raise(vm, MRBC_CLASS(TypeError), "pixel must be an Integer");
      return;
    }

    uint32_t rgb = (uint32_t)mrbc_integer(pixel);
    int offset = index * 3;
    buffer.array->data[offset] = mrbc_integer_value((rgb >> 16) & 0xff);
    buffer.array->data[offset + 1] = mrbc_integer_value((rgb >> 8) & 0xff);
    buffer.array->data[offset + 2] = mrbc_integer_value(rgb & 0xff);
  }

  mrbc_decref(&buffer);
  SET_NIL_RETURN();
}

void
mrbc_daisenkofun_illumination_init(mrbc_vm *vm)
{
  mrbc_class *daisenkofun = mrbc_define_module(vm, "Daisenkofun");
  mrbc_class *illumination = mrbc_define_module_under(
    vm, daisenkofun, "Illumination"
  );
  mrbc_class *display = mrbc_define_class_under(
    vm, illumination, "Display", mrbc_class_object
  );
  mrbc_define_method(vm, display, "_clear_pixels", c_clear_pixels);
  mrbc_define_method(vm, display, "_fill_indices", c_fill_indices);
  mrbc_define_method(vm, display, "_write_pixels", c_write_pixels);
}
