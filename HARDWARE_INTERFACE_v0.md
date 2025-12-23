# Hansen Hardware Interface Definitions v1.0

This document formally defines the Register Map, Commands, and State Machine behaviors for the Hansen Accelerator.

---

## 1. Memory Map (Physical Address Space)

| Base Address | Range Size | Description | Access |
|---|---|---|---|
| `0x0000_0000` | 64 KB | **Local SRAM** (Instruction/Data) | RW |
| `0x4000_0000` | 20 Bytes | **DMA Controller Registers** | RW |

---

## 2. Register Definitions

### DMA Controller (Base: `0x4000_0000`)

| Offset | Name | Type | Description |
|---|---|---|---|
| `+0x00` | `DMA_SRC_ADDR` | WO | Source Address (PCIe Host Physical Address). |
| `+0x04` | `DMA_DST_ADDR` | WO | Destination Address (Local SRAM Offset). |
| `+0x08` | `DMA_LENGTH` | WO | Length of transfer in Words (4 bytes). |
| `+0x0C` | `DMA_CONTROL` | WO | Control Command Register. |
| `+0x10` | `DMA_STATUS` | RO | Status Flags (Polling). |

#### DMA_CONTROL Bitfields
- **Bit 0**: `START` - Write '1' to begin transfer. Clears automatically.
- **Bit 1**: `INT_EN` - Enable Interrupt on completion.

#### DMA_STATUS Bitfields
- **Bit 0**: `BUSY` - 1 if DMA or Core is active, 0 if Idle.
- **Bit 1**: `INT_EN` - Enable Interrupt on completion.

#### DMA_STATUS Bitfields
- **Bit 0**: `BUSY` - 1 if DMA or Core is active, 0 if Idle.
- **Bit 1**: `ERROR` - 1 if last command failed (e.g. Bus Error).

### 2.1 Control Path Reference
For detailed **Control Signal Truth Tables** (RegWrite, MemRead, ALUOp) and Instruction Encoding, refer to the [ISA Formal Specification](ISA_REFERENCE.md). This separation ensures modular documentation for Core vs SoC.

---

## 3. Commands & States

### DMA State Machine
1.  **IDLE**: `dma_busy = 0`. Ready for configuration.
2.  **RUNNING**: `dma_busy = 1`. Activated when `DMA_CONTROL[0]` is written to 1. Ignores further configuration writes.
3.  **COMPLETE**: Triggers `irq_done`. Returns to IDLE.

### Interrupts
- **IRQ 0 (Bit 0)**: `DMA_COMPLETE`. Triggered when `dma_busy` transitions from 1 to 0.
- **IRQ 1 (Bit 1)**: `CORE_HALT`. Triggered when Core executes `HALT` instruction.

## 5. Bus Arbitration & Priorities
The System-on-Chip (SoC) uses a fixed-priority arbiter for the shared SRAM.

| Priority | Master | Description |
|---|---|---|
| **1 (High)** | **DMA Controller** | Guaranteed bandwidth. Blocks CPU/PCIe during bulk transfers. |
| **2 (Med)** | **PCIe Target** | External Host access. Simulates "Cycle Stealing". |
| **3 (Low)** | **Hansen Core** | The CPU stalls if DMA or PCIe accesses memory. |

## 6. Command Queue & Lifecycle
Currently, the hardware implements a **Depth-1 Command Queue** (Synchronous).

1.  **HOST**: Writes `SRC`, `DST`, `LEN`.
2.  **HOST**: Writes `CTRL=START`.
3.  **HW**: Sets `STATUS=BUSY`.
4.  **HW**: Performs Copy.
5.  **HW**: Clears `STATUS=BUSY`, Asserts `IRQ`.
6.  **HOST**: Sees `IRQ` or polls `STATUS`.



---

## 4. Error Handling
- **Invalid Address**: Writes to unmapped regions are ignored silently in current RTL.
- **DMA Bounds**: DMA Controller does not check bounds against SRAM size in hardware (Logic error risk). Software MUST ensure `DST + LEN <= 64KB`.

---
*This document serves as the binding contract for Driver developers and RTL verification.*
