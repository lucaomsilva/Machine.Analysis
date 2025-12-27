# System Requirements Specification (SRS)

| Metadado            | Detalhe                                                |
| :------------------ | :----------------------------------------------------- |
| **Projeto**         | Sistema de Monitoramento Industrial Distribuído (SMID) |
| **ID do Documento** | SMID-DOC-002                                           |
| **Versão**          | 1.0                                                    |
| **Status**          | Pronto                                                 |
| **Data**            | 23/12/2025                                             |

## Histórico de Revisão

| Versão | Data | Autor | Descrição da Mudança |
| :--- | :--- | :--- | :--- |
| 1.0 | 23/12/2025 | Lucas Moura da Silva | Atualização para ESP32-S3, Display SPI, Logs 24h e Shell. |

---

## 1. Requisitos de Arquitetura de Hardware (ARCH)
*Definições físicas necessárias para suportar a carga de software e processamento.*

- [ ] **[SYS-ARCH-001] SoC Master**
  > O Gateway deve utilizar o SoC **ESP32-S3** (Série WROOM-1 ou superior) para garantir suporte a instruções vetoriais (aceleração gráfica) e conectividade Bluetooth 5.0 Long Range.

- [ ] **[SYS-ARCH-002] Memória Externa (PSRAM)**
  > O sistema deve ter no mínimo **2MB de PSRAM** habilitada via Octal SPI para alocar os *buffers* de vídeo (Double Buffering), deixando a SRAM interna livre para as pilhas de Wi-Fi e Bluetooth Mesh.

## 2. Requisitos de Recursos e Performance (PERF)
*Gestão de concorrência, tempo real e uso de memória.*

- [ ] **[SYS-PERF-001] Estratégia de Buffer Gráfico**
  > O subsistema gráfico (LVGL) deve utilizar **Double Buffering** alocado na PSRAM. Isso visa eliminar o efeito de *tearing* (rasgos na imagem) e garantir uma taxa de atualização mínima de **15 FPS** na interface.

- [ ] **[SYS-PERF-002] Prioridade Preemptiva**
  > A *thread* de gestão da Rede Mesh e o Watchdog Timer devem ter prioridade de execução estritamente superior à *thread* de renderização gráfica (GUI), garantindo que animações de tela nunca causem perda de pacotes da rede.

- [ ] **[SYS-PERF-003] Desgaste da Flash (Wear Leveling)**
  > A escrita de logs deve ser realizada em blocos (*batch write*) a partir de um buffer em RAM, minimizando operações físicas de escrita para garantir vida útil da Flash superior a 5 anos.

## 3. Requisitos Funcionais de Interface (UI)
*Comportamento visual e interação no Display ST7796S.*

- [ ] **[SYS-UI-001] Modo Seguro de OTA**
  > Durante o processo de escrita crítica na Flash (Download/Swap de Firmware), a interface gráfica deve entrar em estado de "Congelamento Seguro" ou exibir apenas uma barra de progresso estática, evitando concorrência no barramento SPI/CPU.

- [ ] **[SYS-UI-002] Tratamento de Erro de Renderização**
  > Caso ocorra falha de alocação de memória (*Heap Exhaustion*) para desenhar um objeto, o sistema não deve reiniciar (Kernel Panic), mas sim registrar o erro e omitir o objeto ou exibir um *placeholder* visual.

## 4. Requisitos de Dados e Conectividade (DATA)
*Ciclo de vida do dado, armazenamento local e nuvem.*

- [ ] **[SYS-DATA-001] Retenção Circular (24h)**
  > O sistema deve armazenar logs de telemetria na Flash (LittleFS) por um período rotativo de 24 horas. Após esse tempo, os arquivos mais antigos devem ser automaticamente sobrescritos (FIFO).

- [ ] **[SYS-DATA-002] Sincronização Store & Forward**
  > O sistema deve possuir um agente que envia os logs armazenados para a nuvem em intervalos configuráveis. Se não houver conexão Wi-Fi, os dados devem permanecer seguros na Flash até que a conexão retorne.

- [ ] **[SYS-DATA-003] Resiliência Offline**
  > O Gateway deve ser capaz de operar a rede Mesh (local) indefinidamente mesmo sem conexão com a internet (Wi-Fi), garantindo que a operação da fábrica não dependa da nuvem.

## 5. Requisitos de Manutenção e OTA (MNT)
*Atualização segura de firmware.*

- [ ] **[SYS-MNT-001] Atualização Dual-Slot (A/B)**
  > O sistema deve utilizar o bootloader **MCUboot** com duas partições de aplicação. A atualização deve ser gravada no slot secundário e só ativada após validação de assinatura criptográfica.

- [ ] **[SYS-MNT-002] Rollback Automático**
  > Caso a nova versão do firmware falhe ao inicializar (Watchdog Timeout ou Boot Loop), o bootloader deve reverter automaticamente para a versão anterior estável.

## 6. Requisitos de Observabilidade e Debug (DBG)
*Ferramentas de diagnóstico para engenharia.*

- [ ] **[SYS-DBG-001] Logging Estruturado (Deferred)**
  > O sistema deve implementar *logging* assíncrono via USB-CDC ou Telnel, permitindo que eventos críticos sejam registrados e formatados sem bloquear o processamento em tempo real das threads principais.

- [ ] **[SYS-DBG-002] Shell Interativo Híbrido (CLI)**
  > O sistema deve disponibilizar o terminal de linha de comando simultaneamente via interface Serial (USB-CDC) e Rede (Telnet). O acesso via Serial deve ter prioridade e estar sempre disponível, independentemente do estado da conexão Wi-Fi.

---
**Legenda de Status:**
- [ ] Aberto / Não Iniciado
- [x] Implementado e Testado
