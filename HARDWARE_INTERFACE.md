# Hansen Hardware Interface Definitions v1.0

This document formally defines the Register Map, Commands, and State Machine behaviors for the Hansen Accelerator.

---

## 1. Memory Map (Physical Address Space)

| Base Address | Range Size | Description | Access |
|---|---|---|---|
| `0x0000_0000` | 64 KB | **Local SRAM** (Instruction/Data) | RW |
| `0x4000_0000` | 16 Bytes | **DMA Controller Registers** | W |

---

## 2. Register Definitions

### DMA Controller (Base: `0x4000_0000`)

| Offset | Name | Type | Description |
|---|---|---|---|
| `+0x00` | `DMA_SRC_ADDR` | WO | Source Address (PCIe Host Physical Address). |
| `+0x04` | `DMA_DST_ADDR` | WO | Destination Address (Local SRAM Offset). |
| `+0x08` | `DMA_LENGTH` | WO | Length of transfer in Words (4 bytes). |
| `+0x0C` | `DMA_CONTROL` | WO | Control Command Register. |

#### DMA_CONTROL Bitfields
- **Bit 0**: `START` - Write '1' to begin transfer. Clears automatically.
- **Bit 1**: `INT_EN` - Enable Interrupt on completion (Not yet implemented in HW, assumed ON).

---

## 3. Commands & States

### DMA State Machine
1.  **IDLE**: `dma_busy = 0`. Ready for configuration.
2.  **RUNNING**: `dma_busy = 1`. Activated when `DMA_CONTROL[0]` is written to 1. Ignores further configuration writes.
3.  **COMPLETE**: Triggers `irq_done`. Returns to IDLE.

### Interrupts
- **IRQ 0**: DMA Transfer Complete.
- **IRQ 1**: Kernel Core Halt (Optional future expansion).

---

## 4. Error Handling
- **Invalid Address**: Writes to unmapped regions are ignored silently in current RTL.
- **DMA Bounds**: DMA Controller does not check bounds against SRAM size in hardware (Logic error risk). Software MUST ensure `DST + LEN <= 64KB`.

---
*This document serves as the binding contract for Driver developers and RTL verification.*
