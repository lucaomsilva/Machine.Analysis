/*
 * Project: SMID - Distributed Industrial Monitoring System
 * File: main.c
 * Description: Firmware Entry Point and System Initialization
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/shell/shell.h>
#include <zephyr/version.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

int main(void)
{
    LOG_INF("==========================================");
    LOG_INF("   SMID Gateway - System Starting...      ");
    LOG_INF("   Board: %s", CONFIG_BOARD);
    LOG_INF("   Zephyr OS: %s", KERNEL_VERSION_STRING);
    LOG_INF("==========================================");

    while (1) {
        k_sleep(K_SECONDS(5));
        LOG_DBG("Heartbeat: System operating normally.");
    }

    return 0;
}
