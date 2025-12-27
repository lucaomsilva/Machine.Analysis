# Concept of Operations (ConOps)

| Metadado            | Detalhe                                                |
| :------------------ | :----------------------------------------------------- |
| **Projeto**         | Sistema de Monitoramento Industrial Distribuído (SMID) |
| **ID do Documento** | SMID-DOC-001                                           |
| **Versão**          | 1.0                                                    |
| **Status**          | Pronto                                                 |
| **Data**            | 23/12/2025                                             |

---

## 1. Escopo
Este documento descreve as características operacionais do sistema SMID. O sistema destina-se a fornecer monitoramento de telemetria em tempo real para ambientes industriais sem infraestrutura de rede cabiada, utilizando um Gateway Central baseado em ESP32-S3 e nós sensores via Redes Mesh.

## 2. Situação Atual e Oportunidades
Atualmente, o monitoramento de motores e esteiras na planta fabril é realizado manualmente através de rondas de inspeção.

### 2.1. Deficiências do Processo Atual
* **Latência de Informação:** Falhas que ocorrem entre rondas não são detectadas imediatamente.
* **Custo de Infraestrutura:** A instalação de cabeamento Ethernet em máquinas antigas (Retrofit) possui custo proibitivo.
* **Ausência de Histórico:** A leitura manual não permite análise de tendências de longo prazo.

## 3. Conceito do Sistema Proposto
O SMID propõe uma arquitetura descentralizada onde a inteligência é distribuída entre nós sensores e um concentrador inteligente para visualização imediata.

### 3.1. Arquitetura Operacional
O sistema é composto por três elementos principais:
1.  **Nós Sensores (Nodes):** Dispositivos alimentados por bateria/rede que coletam dados e os transmitem via Mesh.
2.  **Gateway Mestre (HMI):** Dispositivos ESP32-S3 com display ST7796S responsável pela visualização local e gestão da rede. Podendo transitar pelo perímetro da fábrica.
3.  **Interface de Manutenção:** Mecanismo OTA (Over-The-Air) via Wi-Fi para atualizações de segurança e funcionalidades.

### 3.2. Cenários de Uso (User Stories)

#### Cenário A: Monitoramento de Rotina
> O **Operador de Máquina** aproxima-se do Gateway Mestre instalado no painel central. Ele visualiza gráficos de temperatura das últimas 24 horas. O sistema opera de forma resiliente (30 FPS) utilizando a aceleração gráfica do ESP32-S3.

#### Cenário B: Alerta de Falha Crítica
> Um **Nó Sensor** detecta vibração acima do limite. Ele envia uma mensagem de alta prioridade na rede Mesh. O Gateway interrompe a visualização padrão e exibe um alerta vermelho piscante em menos de 1s.

#### Cenário C: Atualização de Firmware (OTA)
> O **Engenheiro de Sistemas** envia uma nova versão de firmware. O Gateway entra em modo de segurança, desativa a renderização complexa para economizar memória, aplica a atualização no slot secundário e reinicia automaticamente.

#### Cenário D: Adição de um novo nó
> O **Engenheiro de Manutenção** pode adicionar um novo nó em um novo máquinario e ele será integrado na Rede Mesh automaticamente.

## 4. Ambiente Operacional
* **Físico:** Chão de fábrica com presença de poeira e vibração.
* **Eletromagnético:** Alta interferência (ruído) que exige retransmissão de pacotes na rede Mesh.
* **Energia:** Gateway e Sensores alimentados por bateria ou 24V DC.
* **Rede:** Conexão estava por toda fábrica.

## 5. Matriz de Stakeholders

| Papel               | Responsabilidade        | Interesse no Sistema                      |
| :------------------ | :---------------------- | :---------------------------------------- |
| **Operador**        | Monitorar status diário | Interface clara e legível (Display 3.5"). |
| **Eng. Manutenção** | Analisar causas raiz    | Logs de erro e dados históricos.          |
| **Desenvolvedor**   | Manter o sistema        | Facilidade de atualização (OTA) e Debug.  |

## 6. Impactos Operacionais
* **Redução de Paradas:** Espera-se reduzir o tempo de inatividade não planejado em 40%.
* **Treinamento:** Operadores necessitarão de treinamento básico, cerca de 1 hora, para interagir com a nova interface *touch*.

---
