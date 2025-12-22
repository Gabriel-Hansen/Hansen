# HANSEN ACCELERATOR: MANUAL PRÁTICO (v1.0)
**Guia Definitivo de Desenvolvimento, Arquitetura e Implementação.**

---

## Índice
1. [Visão Geral](#1-visão-geral)
2. [Arquitetura de Hardware](#2-arquitetura-de-hardware)
3. [Stack de Software](#3-stack-de-software)
4. [Toolchain (Compilador)](#4-toolchain-compilador)
5. [Guia de "Silicon" (ASIC)](#5-guia-de-silicon-asic)
6. [Tutoriais](#6-tutoriais)

---

## 1. Visão Geral
O **Hansen Accelerator** é um co-processador RISC-V de 32-bits voltado para offloading de física e simulação em jogos. Diferente de uma GPU, ele é otimizado para lógica serial complexa e branches imprevisíveis, aliviando a CPU principal (x86 host).

### Destaques do Protótipo
- **Core**: RISC-V (RV32I) com Pipeline de 5 Estágios.
- **Periféricos**: DMA Controller integrado para transferências de memória rápidas.
- **Interface**: PCIe (simulado via Mock e Driver Linux real).
- **Frequência Alvo**: 50MHz (130nm process).

---

## 2. Arquitetura de Hardware
O design está localizado em `hardware/` e é escrito em Verilog-2012.

### 2.1 Hansen Core (`hansen_core.v`)
Implementa um pipeline clássico de 5 estágios:
1.  **IF (Fetch)**: Busca instrução na SRAM local.
2.  **ID (Decode)**: Decodifica Opcode e lê Banco de Registradores.
3.  **EX (Execute)**: ALU realiza somas, subtrações e cálculo de endereços.
4.  **MEM (Memory)**: Acesso à memória de dados (Load/Store).
5.  **WB (Writeback)**: Escreve resultado no registrador de destino.

### 2.2 SoC & DMA (`hansen_soc.v`, `dma_controller.v`)
O SoC integra o Core com uma memória SRAM de 64KB e um Bus Arbiter.
- **DMA**: Permite que o Host programe cópias de memória (PCIe -> SRAM) sem intervenção do Core, gerando uma interrupção (`irq`) ao finalizar.

---

## 3. Stack de Software

### 3.1 Kernel Driver (`kernel_driver/hansen_pci.c`)
Um módulo de kernel Linux (`.ko`) real.
- Mapeia a memória do dispositivo (BAR0) para o espaço de kernel.
- Cria `/dev/hansen0` para interação via user-space.
- Suporta leitura/escrita direta nos registradores do hardware.

### 3.2 Simulador (`simulator/`)
Ferramenta escrita em Rust para validar a lógica sem necessidade de hardware físico.
- Executa binários `.bin` fiéis ao hardware.
- Gera saída JSON para visualização gráfica.

---

## 4. Toolchain (Compilador)
Não dependemos mais de Assembly manual. Desenvolvemos um toolchain próprio em Python.

### 4.1 Mini-C Compiler (`tools/minicc.py`)
Compila um subset de C para Assembly Hansen.
Suporta:
- Ponteiros (`int *p = 0x100; *p = 10;`)
- Aritmética (`+`, `-`)
- Loops (`while(1)`)

### 4.2 Assembler (`tools/assembler.py`)
Transforma o Assembly (`.asm`) em código de máquina binário (`.bin`) pronto para o hardware ou simulador.

---

## 5. Guia de "Silicon" (ASIC)
Para fabricação real em silício (130nm).

### Configuração OpenLane (`asic/config.tcl`)
- **Processo**: SkyWater 130nm (OpenMPW).
- **Área**: 2.92mm x 3.52mm.
- **Pinos**: Mapeados para suportar interface PCIe e Debug.

---

## 6. Tutoriais

### Executar "Hello World" Físico (Simulado)

1.  **Escreva o Kernel (C)**:
    ```c
    // test.c
    int x = 10;
    int y = 20;
    int z = x + y; // z = 30
    ```

2.  **Compile**:
    ```bash
    python3 tools/minicc.py test.c            # Gera test.asm
    python3 tools/assembler.py test.asm test.bin # Gera test.bin
    ```

3.  **Execute no Simulador**:
    ```bash
    ./simulator/target/debug/simulator test.bin
    ```

4.  **Verifique no Hardware (RTL)**:
    ```bash
    iverilog -g2012 -o soc_sim hardware/hansen_soc.v hardware/hansen_core.v
    vvp soc_sim
    ```

---
*Gerado automaticamente pelo Agente Antigravidade em 2025.*
