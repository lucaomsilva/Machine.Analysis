#include <zephyr/kernel.h>
#include <zephyr/drivers/display.h>
#include <zephyr/logging/log.h>
#include "./display.h"

LOG_MODULE_REGISTER(display, LOG_LEVEL_INFO);

static const struct device *display_dev = NULL;

static uint16_t line_buffer[320];

int display_init(void)
{
  return 0;
}
