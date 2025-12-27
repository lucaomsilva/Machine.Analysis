# System Architecture

| Metadado            | Detalhe                                                |
| :------------------ | :----------------------------------------------------- |
| **Projeto**         | Sistema de Monitoramento Industrial Distribuído (SMID) |
| **ID do Documento** | SMID-DOC-002                                           |
| **Versão**          | 1.0                                                    |
| **Status**          | Pronto                                                 |
| **Data**            | 23/12/2025                                             |
| **Hardware**        | ESP32-S3 (Gateway) + ESP32/nRF (Nodes)                 |
| **OS:**             | Zephyr RTOS 3.7.x                                      |

---

## 1. Visão Geral (C4 Context Diagram)
O diagrama abaixo ilustra o contexto de alto nível do sistema e suas interações com o ambiente externo.

```mermaid
graph TD
    User((Operador))
    Eng((Eng. Sistemas))
    
    subgraph "Chão de Fábrica (Mesh Network)"
        Node1[Sensor Motor A]
        Node2[Sensor Esteira B]
        Node3[Sensor Temp C]
    end

    subgraph "Central de Controle"
        Gateway[Gateway Mestre<br/>ESP32-S3 + TFT]
    end

    Cloud[Servidor OTA<br/>HTTP/AWS]

    %% Relações
    User -->|Visualiza Dados| Gateway
    Eng -->|Envia Firmware| Cloud
    Cloud -.->|Wi-Fi / Download| Gateway
    
    Node1 <-->|Bluetooth Mesh| Gateway
    Node2 <-->|Bluetooth Mesh| Gateway
    Node3 <-->|Bluetooth Mesh| Node1
    Node3 <-->|Bluetooth Mesh| Node2 

```

## 2. Arquitetura de Hardware (Gateway)

- **SoC**: ESP32-S3-WROOM-1 (Dual Core, 240MHz, 16MB PSRAM).
- **Display**: ST7796S (3.5" TFT) via SPI (40MHz), 320x480 RGB.
- **Armazenamento**: Flash Interna particionada para suporte a Rollback (MCUboot).

```mermaid
graph LR
    %% Atores Externos (Quem envia comandos)
    subgraph "Interfaces de Operação"
        EngLocal[Eng. Local<br/> - Cabo USB]
        EngRemote[Eng. Remoto<br/> - Wi-Fi / Telnet]
        User[Operador<br/> - Visualização]
    end

    subgraph "ESP32-S3 SoC"
        subgraph "Processamento"
            Core0[Core 0<br/>Wi-Fi Stack & Mesh<br/>Server Telnet]
            Core1[Core 1<br/>App Logic & Shell Core<br/>LVGL Engine]
        end
        
        subgraph "Controladores Internos"
            DMA[DMA Controller]
            USB_HW[USB-Serial/JTAG<br/>Controller]
        end
    end

    subgraph "Periféricos Externos"
        TFT[Display ST7796S<br/>SPI 4-Wire]
        Flash[Flash Externa<br/>LittleFS & Logs]
        Antenna[Antena 2.4GHz]
    end

    %% --- Fluxo de Comandos e Debug (CLI) ---
    EngLocal <==>|UART/CDC Comandos| USB_HW
    USB_HW <-->|Interrupção| Core1
    
    EngRemote <==>|TCP/IP Comandos| Antenna
    Antenna <-->|RF Signal| Core0
    Core0 <-->|IPC / Buffer de Rede| Core1

    %% --- Fluxo de Visualização Gráfica (HMI) ---
    Core1 -->|Renderiza Buffer| DMA
    DMA ==>|SPI Bus - Data| TFT
    TFT -.->|Interface Gráfica| User

    %% --- Fluxo de Armazenamento ---
    Core1 <-->|Leitura/Escrita Logs| Flash
```

## 3. Arquitetura de Software

### 3.1 Zephyr Stack

Uso do Zephyr RTOS, utilizando uma arquitetura em camadas para desacoplar o hardware da lógica de negócio.

```mermaid
classDiagram
    direction BT
    class Hardware {
        ESP32-S3 SoC
        USB-CDC / UART0
        ST7796S Display
        Flash Storage
    }

    class ZephyrKernel {
        Scheduler / Threads
        Workqueues
        Memory Slabs
    }

    class OSServices {
        <<Cross-Cutting>>
        Logging Subsystem (Log Core)
        Shell Subsystem (CLI)
        File System (LittleFS)
    }

    class Drivers {
        UART / USB Driver
        SPI Driver
        Display Driver
    }

    class Middleware {
        Bluetooth Mesh Stack
        LVGL (Graphics)
        MCUboot
    }

    class Application {
        App Logic
        UI Controller
        Debug Commands
    }

    %% Relacionamentos
    Hardware <.. Drivers
    Drivers <.. ZephyrKernel
    ZephyrKernel <.. OSServices
    OSServices <.. Middleware
    OSServices <.. Application
    Middleware <.. Application
    
    %% Fluxo do Debug
    Hardware <.. OSServices : UART I/O
```

### 3.2 Subsistemas de gerenciamento

```mermaid
classDiagram
    direction BT

    %% Camada de Transporte Físico
    class UART_Driver {
        +interrupt_handler()
        +fifo_read()
    }
    class Network_Stack {
        +TCP/IP (LwIP)
        +Telnet Server (Port 23)
    }

    %% Camada de Abstração do Shell (Zephyr)
    class Shell_Backend_UART {
        +output()
        +input_hook()
    }
    class Shell_Backend_Telnet {
        +output()
        +input_hook()
    }
    
    %% O Cérebro
    class Shell_Core {
        +command_parser()
        +history_buffer
        +execute_cmd()
    }

    %% Aplicação
    class App_Commands {
        +cmd_mesh_status()
        +cmd_storage_ls()
    }

    %% Relações
    UART_Driver <.. Shell_Backend_UART
    Network_Stack <.. Shell_Backend_Telnet
    
    Shell_Backend_UART --|> Shell_Core : Injeta Texto
    Shell_Backend_Telnet --|> Shell_Core : Injeta Texto
    
    Shell_Core ..> App_Commands : Invoca
```

## 4. Fluxo de Dados (Sequence Diagram)

### 4.1 Mensagem crítico

**O fluxo crítico do sistema**: Recebimento de um alarme via Mesh e atualização da tela.

```mermaid
sequenceDiagram
    participant Sensor as Nó Sensor
    participant Mesh as BT Mesh Stack (Gateway)
    participant App as Lógica da App
    participant LVGL as LVGL Engine
    participant Display as ST7796S (SPI)

    Sensor->>Mesh: Envia dados sobre algo crítico (Alta Prioridade)
    Mesh->>App: Callback (New Message)
    
    rect rgb(148, 98, 230)
    Note over App, Display: Processamento Crítico
    App->>App: Analisa do Limite Crítico
    App->>LVGL: lv_label_set_text("ALERTA!")
    App->>LVGL: lv_obj_set_style_bg_color(RED)
    end
    
    LVGL->>LVGL: Renderiza Buffer (PSRAM)
    LVGL->>Display: Flush Buffer (DMA Transfer)
    Display-->>User: Tela Vermelha
```


### 4.2 Atualização dos dados

Este diagrama detalha como garantimos que a alta frequência de mensagens da rede Mesh não bloqueie a renderização gráfica, utilizando Filas de Mensagens (Message Queues) do RTOS para desacoplamento.

- **Problema**: Se o LVGL tentar desenhar no exato momento que o rádio Bluetooth recebe um pacote, pode haver corrupção de memória ou atraso na rede.

- **Solução**: O Produtor (Mesh Thread) apenas coloca o dado na fila. O Consumidor (UI Thread) processa quando possível.

```mermaid
sequenceDiagram
    autonumber
    participant Node as Sensor Node
    participant MeshStack as Mesh Stack (Core 0)
    participant DataQueue as k_msgq (RAM)
    participant UIThread as UI Task (Core 1)
    participant Display as ST7796S

    Note over Node, MeshStack: Domínio Bluetooth (Alta Prioridade)
    Node->>MeshStack: Publica Dados (Temp = 45.5°C)
    MeshStack->>MeshStack: Valida Pacote & Descriptografa
    MeshStack->>DataQueue: k_msgq_put(struct sensor_data)
    Note right of MeshStack: Stack Mesh libera CPU imediatamente

    Note over UIThread, Display: Domínio Aplicação (Baixa Prioridade)
    loop UI Refresh Cycle
        UIThread->>DataQueue: k_msgq_get()
        alt Nova Mensagem?
            UIThread->>UIThread: Atualiza Variável Local
            UIThread->>UIThread: lv_label_set_text("45.5°C")
            UIThread->>UIThread: lv_chart_set_next_value()
        end
        UIThread->>Display: lv_task_handler() (Render & Flush)
    end
```

### 4.3 Fluxo de Armazenamento de Logs (Persistência)

```mermaid
flowchart TD
    subgraph "Aquisição de Dados"
        Sensor[Evento / Telemetria] --> RAM_Buf[Buffer RAM]
    end

    subgraph "Gestão de Armazenamento Local (LittleFS)"
        RAM_Buf -->|Batch Write - A cada 10 minutos | FileSys[Sistema de Arquivos]
        
        FileSys -- Grava --> HourFile{Arquivo da Hora Atual?}
        HourFile -- Sim --> Append[Anexar ao arquivo]
        HourFile -- Não --> Rotate[Rotacionar: Apagar Mais Antigo -> Criar Novo]
        
        Rotate --> Append
    end

    subgraph "Sincronização Nuvem (Cloud Sync)"
        Timer[Cron Job - A cada 1h] --> Uploader[Cloud Upload Task]
        Uploader -->|Lê Arquivo Fechado| FileSys
        Uploader -->|MQTT / HTTP POST| Cloud[AWS IoT / Azure / Google]
        
        Cloud -->|Ack | Uploader
        Uploader -->|Mark as Sent| FileSys
    end
```

### 4.4 Concorrência entre UART e Telnet


```mermaid
sequenceDiagram
    participant Serial as Eng. Serial
    participant Telnet as Eng. Telnet
    participant Shell as Shell Core
    participant App as Aplicação

    Note over Serial, App: Cenário de Concorrência
    Serial->>Shell: Digita "mesh scan"
    Telnet->>Shell: Digita "log status"
    
    Shell->>Shell: Serializa as requisições (FIFO)
    
    Shell->>App: Executa "mesh scan"
    App-->>Shell: Retorna Lista de Nós
    Shell-->>Serial: Imprime no Cabo USB
    
    Shell->>App: Executa "log status"
    App-->>Shell: Retorna "OK"
    Shell-->>Telnet: Imprime no Wi-Fi
```

## 5. Atualização via OTA (Over The Air)

O sistema utiliza uma estratégia de atualização A/B (Dual Slot) gerenciada pelo bootloader MCUboot. Isso garante que o sistema nunca fique num estado inconsistente ("brickado") se a energia cair durante a atualização.

- **Slot 0 (Primary)**: Onde roda a aplicação atual.

- **Slot 1 (Secondary)**: Onde a nova imagem é gravada.

- **Scratch**: Área temporária usada pelo MCUboot para trocar (swap) os conteúdos dos slots.

```mermaid
stateDiagram-v2
    direction TB
    
    state "Aplicação (Zephyr)" as App {
        [*] --> Idle
        Idle --> Downloading: Recebe Comando OTA
        Downloading --> Verifying: Download Concluído (Slot 1)
        Verifying --> RequestTest: Assinatura OK?
        RequestTest --> Rebooting: Marca imagem como "Teste"
    }

    state "Bootloader (MCUboot)" as Boot {
        Rebooting --> CheckSlots: Boot
        CheckSlots --> Swap: Imagem "Teste" encontrada no Slot 1
        Swap --> Validate: Troca conteúdos (Slot 0 <-> Slot 1)
        Validate --> RunNew: Boot na Nova Versão
    }

    state "Confirmação (Nova versão)" as NewApp {
        RunNew --> SelfTest: Verifica Periféricos
        SelfTest --> Confirm: Tudo OK (img_mgmt_confirm)
        SelfTest --> Revert: Falha Crítica (Watchdog)
    }

    Revert --> Swap: Rollback Automático no próximo Boot
```

## 6. Arquitetura de Observabilidade e Debug
O sistema implementa uma interface de diagnóstico bidirecional sobre USB-CDC (Serial), permitindo inspeção em tempo real sem interromper a operação da interface gráfica (HMI) ou da rede Mesh.

### 6.1. Diagrama de Fluxo de Debug (Shell & Log)

```mermaid
sequenceDiagram
    participant EngLocal as Eng. (Cabo USB)
    participant EngRemote as Eng. (Wi-Fi)
    participant UART as Driver USB-CDC
    participant TCP as Stack TCP/IP
    participant Shell as Zephyr Shell Core
    participant App as Aplicação

    Note over EngLocal, App: Acesso Físico (Prioritário)
    EngLocal->>UART: "kernel uptime"
    UART->>Shell: Backend Serial
    Shell->>App: Executa Comando
    App-->>Shell: Retorna Resultado
    Shell-->>UART: Print
    UART-->>EngLocal: Exibe no Terminal

    Note over EngLocal, App: Acesso Remoto (Conveniência)
    EngRemote->>TCP: Telnet Connect (Port 23)
    TCP->>Shell: Backend Telnet (Sessão Nova)
    EngRemote->>TCP: "mesh status"
    TCP->>Shell: Processa Texto
    Shell->>App: Consulta Mesh
    App-->>Shell: Retorna Status JSON
    Shell-->>TCP: Envia Pacote TCP
    TCP-->>EngRemote: Exibe no Laptop
```

### 6.2. Estrutura de Comandos do Shell

O sistema expõe uma árvore de comandos customizados para manutenção em campo:

**kernel**: Comandos nativos (uptime, threads, stacks).

**log**: Controle de níveis de log (ex: log enable info).

**fs**: Manipulação de arquivos (ls, cd, cat).

**app**: Comandos da aplicação específica:

  - `app mesh status`: Mostra vizinhos e rotas.

  - `app ota exec`: Força o início do download.

  - `app storage reset`: Formata a partição LittleFS.

**sensor**: Comando para leitura imediata dos sensores.
