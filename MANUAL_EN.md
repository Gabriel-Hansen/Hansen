# HANSEN ACCELERATOR: PRACTICAL MANUAL (v1.0)
**Definitive Guide to Development, Architecture, and Implementation.**

---

## Table of Contents
1. [Overview](#1-overview)
2. [Hardware Architecture](#2-hardware-architecture)
3. [Software Stack](#3-software-stack)
4. [Toolchain (Compiler)](#4-toolchain-compiler)
5. [Silicon Guide (ASIC)](#5-silicon-guide-asic)
6. [Tutorials](#6-tutorials)

---

## 1. Overview
The **Hansen Accelerator** is a 32-bit RISC-V co-processor designed for offloading physics and simulation workloads in gaming. Unlike a GPU, it is optimized for complex serial logic and unpredictable branches, relieving the main CPU (x86 host).

### Prototype Highlights
- **Core**: RISC-V (RV32I) with 5-Stage Pipeline.
- **Peripherals**: Integrated DMA Controller for fast memory transfers.
- **Interface**: PCIe (simulated via Mock and real Linux Driver).
- **Target Frequency**: 50MHz (130nm process).

---

## 2. Hardware Architecture
The design is located in `hardware/` and is written in Verilog-2012.

### 2.1 Hansen Core (`hansen_core.v`)
Implements a classic 5-stage pipeline:
1.  **IF (Fetch)**: Fetches instruction from local SRAM.
2.  **ID (Decode)**: Decodes Opcode and reads Register File.
3.  **EX (Execute)**: ALU performs additions, subtractions, and address calculations.
4.  **MEM (Memory)**: Accesses data memory (Load/Store).
5.  **WB (Writeback)**: Writes result to the destination register.

### 2.2 SoC & DMA (`hansen_soc.v`, `dma_controller.v`)
The SoC integrates the Core with a 64KB SRAM memory and a Bus Arbiter.
- **DMA**: Allows the Host to program memory copies (PCIe -> SRAM) without Core intervention, generating an interrupt (`irq`) upon completion.

---

## 3. Software Stack

### 3.1 Kernel Driver (`kernel_driver/hansen_pci.c`)
- **Stable API**: [C API Reference v1.0](API_REFERENCE.md)
- A real Linux kernel module (`.ko`).
- Maps device memory (BAR0) to kernel space.
- Creates `/dev/hansen0` for user-space interaction.
- Supports direct read/write to hardware registers.

### 3.2 Simulator (`simulator/`)
Tool written in Rust to validate logic without physical hardware.
- Executes `.bin` binaries faithful to the hardware.
- Generates JSON output for graphical visualization.

---

## 4. Toolchain (Compiler)
We no longer depend on manual Assembly. We developed our own toolchain in Python.

### 4.1 Mini-C Compiler (`tools/minicc.py`)
Compiles a subset of C to Hansen Assembly.
Supports:
- Pointers (`int *p = 0x100; *p = 10;`)
- Arithmetic (`+`, `-`)
- Loops (`while(1)`)

### 4.2 Assembler (`tools/assembler.py`)
Transforms Assembly (`.asm`) into binary machine code (`.bin`) ready for hardware or simulator.

---

## 5. Silicon Guide (ASIC)
For real silicon manufacturing (130nm).

### OpenLane Configuration (`asic/config.tcl`)
- **Process**: SkyWater 130nm (OpenMPW).
- **Area**: 2.92mm x 3.52mm.
- **Pins**: Mapped to support PCIe and Debug interface.

---

## 6. Tutorials

### Running a Physical "Hello World" (Simulated)

1.  **Write the Kernel (C)**:
    ```c
    // test.c
    int x = 10;
    int y = 20;
    int z = x + y; // z = 30
    ```

2.  **Compile**:
    ```bash
    python3 tools/minicc.py test.c            # Generates test.asm
    python3 tools/assembler.py test.asm test.bin # Generates test.bin
    ```

3.  **Run in Simulator**:
    ```bash
    ./simulator/target/debug/simulator test.bin
    ```

4.  **Verify in Hardware (RTL)**:
    ```bash
    iverilog -g2012 -o soc_sim hardware/hansen_soc.v hardware/hansen_core.v
    vvp soc_sim
    ```
