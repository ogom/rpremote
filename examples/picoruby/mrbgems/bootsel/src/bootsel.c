/* Software reboot into the RP2040/RP2350 USB BOOTSEL mode. */

#include <stdint.h>

/*
 * R2P2 links pico_bootrom through pico_bootsel_via_double_reset. Declaring
 * the stable Pico SDK entry point here keeps this external mrbgem independent
 * from the SDK's target-specific include paths during the mruby build stage.
 */
#if !defined(PICORB_PLATFORM_POSIX)
extern void rom_reset_usb_boot(uint32_t usb_activity_gpio_pin_mask,
                               uint32_t disable_interface_mask)
  __attribute__((noreturn));
#endif

#if defined(PICORB_VM_MRUBY)

#include <mruby.h>

static mrb_value
mrb_machine_enter_bootsel(mrb_state *mrb, mrb_value self)
{
#if !defined(PICORB_PLATFORM_POSIX)
  rom_reset_usb_boot(0, 0);
#else
  mrb_raise(mrb, E_NOTIMP_ERROR,
            "Machine.enter_bootsel is supported only on RP2040/RP2350");
#endif
  return mrb_nil_value();
}

void
mrb_picoruby_bootsel_gem_init(mrb_state *mrb)
{
  struct RClass *machine = mrb_module_get(mrb, "Machine");
  mrb_define_class_method(mrb, machine, "_enter_bootsel",
                          mrb_machine_enter_bootsel, MRB_ARGS_NONE());
}

void
mrb_picoruby_bootsel_gem_final(mrb_state *mrb)
{
}

#elif defined(PICORB_VM_MRUBYC)

#include <mrubyc.h>

static void
mrbc_machine_enter_bootsel(mrbc_vm *vm, mrbc_value *v, int argc)
{
#if !defined(PICORB_PLATFORM_POSIX)
  rom_reset_usb_boot(0, 0);
#else
  mrbc_raise(vm, MRBC_CLASS(NotImplementedError),
             "Machine.enter_bootsel is supported only on RP2040/RP2350");
  SET_NIL_RETURN();
#endif
}

void
mrbc_bootsel_init(mrbc_vm *vm)
{
  mrbc_class *machine = mrbc_get_class_by_name("Machine");
  mrbc_define_method(vm, machine, "_enter_bootsel", mrbc_machine_enter_bootsel);
}

#endif
