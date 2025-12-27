# Master Test Plan (MTP)

| Metadado              | Detalhe                                                |
| :-------------------- | :----------------------------------------------------- |
| **Projeto**           | Sistema de Monitoramento Industrial Distribuído (SMID) |
| **ID do Documento**   | SMID-DOC-001                                           |
| **Versão**            | 1.0                                                    |
| **Status**            | Pronto                                                 |
| **Data**              | 23/12/2025                                             |
| **Hardware de Teste** | 1x Gateway ESP32-S3 (WROOM-1), 2x Nodes ESP32          |
| **Ferramentas**       | Multímetro, Python Scripts, Comunicação UART           |

---

## 1. Estratégia de Teste
A validação do sistema será realizada em três níveis:

1.  **Testes de Integração (L2):** Validação da comunicação entre módulos (ex: Mesh -> UART -> UI).
2.  **Testes de Sistema (L3):** Validação de fluxos completos de usuário (ex: Atualização OTA).
3.  **Testes de Stress/Confiabilidade:** Validação de comportamento sob carga máxima e falhas forçadas.

---

## 2. Casos de Teste (Test Cases)

### 2.1. Testes de Interface e Performance (UI/PERF)

| ID do Teste | Rastreabilidade | Descrição | Procedimento | Critério de Aceite (Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- |
| **TC-UI-01** | `SYS-PERF-001`<br>`SYS-ARCH-002` | **Fluidez da Interface (FPS)** | 1. Carregar firmware com medidor de FPS habilitado no LVGL.<br>2. Navegar entre abas do menu rapidamente.<br>3. Observar log serial ou contador na tela. | A taxa de quadros (FPS) **não deve cair abaixo de 15 FPS** durante as transições. Não deve haver *tearing* (rasgos) visíveis. |
| **TC-UI-02** | `SYS-UI-001` | **Comportamento durante Escrita na Flash** | 1. Iniciar um comando de gravação de arquivo pesado ou OTA.<br>2. Tentar interagir com o touch screen durante a gravação. | A interface deve exibir ícone de "Ocupado" ou barra de progresso estática. O sistema **não deve travar** (Watchdog timeout) nem apresentar glitch visual. |

### 2.2. Testes de Rede e Mesh (NET)

| ID do Teste | Rastreabilidade | Descrição | Procedimento | Critério de Aceite (Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- |
| **TC-NET-01** | `SYS-PERF-002` | **Prioridade da Mesh sobre UI** | 1. Configurar 2 nós para enviarem dados a cada 100ms (alta carga).<br>2. Forçar re-renderização completa da tela no Gateway.<br>3. Monitorar logs para verificar perda de pacotes. | O Gateway deve receber >95% dos pacotes Mesh mesmo enquanto a interface gráfica está sendo atualizada intensamente. |
| **TC-NET-02** | `SYS-DATA-003` | **Operação Offline** | 1. Desconectar o Gateway do Wi-Fi (Desligar AP).<br>2. Manter a rede Mesh operando por 1 hora.<br>3. Reconectar Wi-Fi. | O sistema não deve reiniciar ao perder Wi-Fi. Ao reconectar, deve enviar os dados acumulados (Store & Forward). |

### 2.3. Testes de Dados e Logs (DATA)

| ID do Teste | Rastreabilidade | Descrição | Procedimento | Critério de Aceite (Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- |
| **TC-DAT-01** | `SYS-DATA-001` | **Rotação de Logs (Simulado)** | 1. Reduzir o tempo de rotação para 1 minuto (via config).<br>2. Encher o buffer de logs via script Python.<br>3. Aguardar 5 ciclos. | O sistema deve apagar automaticamente o arquivo mais antigo e criar o novo sem corromper o sistema de arquivos LittleFS. |
| **TC-DAT-02** | `SYS-DBG-001` | **Logging Assíncrono** | 1. Habilitar logs em nível `DEBUG`.<br>2. Gerar eventos em alta frequência.<br>3. Verificar se o processamento principal trava. | O log deve aparecer na UART com atraso (buffered), mas a aplicação principal (Mesh) não deve sofrer latência perceptível. |

### 2.4. Testes de Manutenção e OTA (OTA)

| ID do Teste | Rastreabilidade | Descrição | Procedimento | Critério de Aceite (Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- |
| **TC-OTA-01** | `SYS-MNT-001` | **Sucesso na Atualização A/B** | 1. Compilar versão v1.1 (mudar cor de um botão).<br>2. Enviar arquivo via Wi-Fi/HTTP.<br>3. Confirmar a imagem. | O sistema deve reiniciar, trocar o slot (MCUboot Swap) e exibir a nova cor. `mcuboot info` deve mostrar Slot 1 ativo. |
| **TC-OTA-02** | `SYS-MNT-002` | **Rollback Automático (Falha)** | 1. Criar versão v1.2 propositalmente "quebrada" (com loop infinito na inicialização).<br>2. Enviar via OTA.<br>3. Aguardar reinício e travamento. | O Watchdog deve reiniciar o ESP32. O MCUboot deve detectar a falha de boot e reverter automaticamente para a v1.1 (Estável). |

### 2.5. Testes de Segurança e Acesso (SEC)

| ID do Teste | Rastreabilidade | Descrição | Procedimento | Critério de Aceite (Pass/Fail) |
| :--- | :--- | :--- | :--- | :--- |
| **TC-SEC-01** | `SYS-DBG-002` | **Acesso Híbrido Shell** | 1. Conectar via Cabo USB e digitar `version`.<br>2. Conectar via Telnet e digitar `mesh status`. | Ambos os terminais devem responder corretamente sem misturar os caracteres de saída. |

