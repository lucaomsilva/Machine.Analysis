/*
 * This file is a HAL (Hardware Abstraction Layer) for the display
*/

#pragma once

#include <stdint.h>
#include <stdbool.h>

int display_init(void);

int display_fill_color(uint16_t color);

int display_is_ready(void);
