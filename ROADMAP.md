# HANSEN ROADMAP (2026-2028)

**From FPGA Prototype to Mass Market Silicon.**

## GAP ANALYSIS: Prototype vs Production
To be considered "Commercial Ready", we need to bridge these gaps:

| Feature | Current Prototype | Production Requirement |
|---|---|---|
| **Pipeline** | Single Cycle (Slow) | 5-Stage Pipeline (Fast) |
| **Data Transfer** | PIO (CPU copy byte-by-byte) | **DMA** (Direct Memory Access) |
| **Toolchain** | Hand-written Assembly | **C/C++ Compiler** (LLVM Backend) |
| **OS Driver** | Polling / Manual IO | **Interrupts** (MSI-X) / Async |
| **Memory** | 64KB Scratchpad | **L1/L2 Cache** + DRAM Controller |

## Year 1: Prototyping & Seed (2026)

### Q1-Q2: FPGA Validation
- **Hardware**: Port Verilog to **Lattice iCE40** and **Xilinx Artix-7** dev boards.
- **Software**: Release Linux Kernel Module (DKMS) to replace mocked driver.
- **Demo**: Run "Quake 1" physics entirely on Hansen Accelerator.
- **Funding Goal**: $500k Pre-Seed (Angel/Accelerator).

### Q3-Q4: Multi-Core Scaling
- **Architecture**: Expand to 4-Core Cluster with shared memory. Impl **Forwarding Unit** to reach CPI ~1.0.
- **Tooling**: LLVM Backend integration for compiling C++ directly to Hansen ISA.
- **Funding Goal**: $2M Seed (Deep Tech VCs).

## Year 2: First Silicon (2027)

### Q1-Q2: MPW Shuttle
- **Fabrication**: Submit design to **SkyWater 130nm** (Open Source shuttle) or TSMC 180nm.
- **Goal**: Receive physical chips.
- **Testing**: Validate that physical silicon matches FPGA behavior.

### Q3-Q4: Dev Kit Production
- **Product**: "Hansen Dev Board 1.0" (PCIe card).
- **Target**: Universities and Research Labs.
- **Price**: < $100 BOM.

## Year 3: Series A & Commercialization (2028)

### Q1-Q4: Gen 2 Architecture
- **Tech**: Move to 28nm/12nm node.
- **Specs**: 1000+ Cores.
- **Market**: Licensing IP to game console manufacturers or selling discret add-in cards for retro-computing enthusiasts.
