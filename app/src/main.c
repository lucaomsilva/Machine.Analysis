/* main.c - Teste de Tela Vermelha ST7796S */
#include <zephyr/kernel.h>
#include <zephyr/drivers/display.h>
#include <zephyr/logging/log.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_INF);

/* Cor Vermelha em Hexadecimal (RGB565) */
#define RED_COLOR 0xF800 

/* Buffer de 1 linha (320 pixels) para economizar memória */
uint16_t line_buffer[320];

void main(void)
{
    /* Pega o dispositivo definido no overlay */
    const struct device *display_dev = DEVICE_DT_GET(DT_CHOSEN(zephyr_display));

    /* 1. Verificação Inicial */
    if (!device_is_ready(display_dev)) {
        LOG_ERR("ERRO FATAL: Driver da tela nao carregou. Verifique o Overlay!");
        return;
    }

    LOG_INF("Hardware encontrado. Ligando display...");
    display_blanking_off(display_dev); // Tira do modo sleep

    /* Prepara a linha vermelha na memória */
    for (int i = 0; i < 320; i++) {
        line_buffer[i] = RED_COLOR; 
    }

    struct display_buffer_descriptor desc;
    desc.pitch = 320;
    desc.width = 320;
    desc.height = 1; // Vamos escrever 1 linha por vez

    while (1) {
        LOG_INF("Enviando comando de pintura VERMELHA...");
        
        /* Pinta as 480 linhas da tela, uma por uma */
        for (int y = 0; y < 480; y++) {
            int ret = display_write(display_dev, 0, y, &desc, line_buffer);
            if (ret != 0) {
                /* Se der erro aqui, é falha grave no SPI */
                LOG_ERR("Falha de envio na linha %d", y); 
            }
        }
        
        LOG_INF("Ciclo concluido. Aguardando 1s...");
        k_sleep(K_SECONDS(1));
    }
}
