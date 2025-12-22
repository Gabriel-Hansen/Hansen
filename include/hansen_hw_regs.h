/*
 * Hansen Hardware Register Definitions
 * Contract Version 1.0
 *
 * Shared between Driver (Kernel) and internal tools.
 */

#ifndef HANSEN_HW_REGS_H
#define HANSEN_HW_REGS_H

// --- Memory Map Base Addresses ---
#define HANSEN_RAM_BASE 0x00000000
#define HANSEN_RAM_SIZE 0x00010000 // 64KB

#define HANSEN_DMA_BASE 0x40000000

// --- DMA Registers Offsets ---
#define REG_DMA_SRC 0x00
#define REG_DMA_DST 0x04
#define REG_DMA_LEN 0x08
#define REG_DMA_CTRL 0x0C

// --- DMA Control Bits ---
#define DMA_CTRL_START (1 << 0)
#define DMA_CTRL_IRQ_EN (1 << 1)

// --- Interrupts ---
#define IRQ_DMA_COMPLETE 0x1

#endif // HANSEN_HW_REGS_H
