# Hansen Hardware Interface Definitions (Future v2.0)

**Status**: DRAFT / PLANNED
**Target**: ASIC / High-End FPGA (Year 2)

This document defines features not yet implemented in v0 RTL but planned for the commercial release.

---

## 1. Advanced DMA (Ring Buffer)
Instead of the synchronous "Depth-1" queue in v0, v2.0 uses a circular buffer in Host Memory.

- **Base Address**: `0x5000_0000` (Control Registers)
- **Mechanism**:
    1.  Host writes descriptors (Src, Dst, Len) to a circular buffer in RAM.
    2.  Host updates `DMA_TAIL_PTR` register.
    3.  Hardware fetches descriptors via PCIe Master.
    4.  Hardware updates `DMA_HEAD_PTR` as it completes jobs.
    5.  Interrupt coalescing minimizes CPU load.

## 2. MSI-X Interrupts
- **Current (v0)**: Single INTx line (Legacy).
- **Future (v2.0)**: MSI-X Support.
    - Vector 0: DMA Completion.
    - Vector 1: Core Error / Trap.
    - Vector 2: User-Defined Software Interrupt.

## 3. Virtual Memory & Cache
- **IOMMU**: Hardware address translation for DMA (Safety).
- **L1 Cache**: 16KB I-Cache / 16KB D-Cache (Direct Mapped).

---
*This document is for architectural alignment only. Do not implement driver support for these features yet.*
