# HANSEN ACCELERATOR

**High-Performance Computational Accelerator for Physics & Simulation Offloading.**

---

## 1. Vision
The Hansen Accelerator is a specialized co-processor designed to relieve x86_64 CPUs from heavy, parallelizable workloads in gaming and simulation contexts. It is not a GPU, and it is not a general-purpose CPU. It is a **Physics Processing Unit (PPU)** reimagined for the modern era, focusing on:
- **Efficiency**: Low power, high throughput for specific kernels.
- **Simplicity**: RISC-V based architecture.
- **Integration**: Seamless PCIe connection with Linux/Windows.

## 2. Architecture

```mermaid
graph TD
    Host[x86_64 Host PC] <-->|PCIe| Driver[Hansen Driver (Linux)]
    Driver <-->|DMA| Mem[Local Memory (64KB+)]
    
    subgraph Accelerator [Hansen Accelerator]
        Mem
        Scheduler
        Core0[RISC-V Core 0]
        Core1[RISC-V Core 1]
        CoreN[RISC-V Core N]
        
        Scheduler --> Core0
        Scheduler --> Core1
        Scheduler --> CoreN
        
        Core0 <--> Mem
        Core1 <--> Mem
        CoreN <--> Mem
    end
```

## 3. Project Status
Current Phase: **Phase 4 (Demos/Prototype)**

| Phase | Description | Status |
|---|---|---|
| **1** | Simulator (Rust) | ✅ Completed |
| **2** | Driver Mock | ✅ Completed |
| **3** | FPGA RTL (Verilog) | ✅ Completed |
| **4** | Demos & Docs | ✅ Completed |
| **5** | FPGA PCB | ⏳ Pending |
| **6** | Silicon (ASIC) | 🔮 Future |

## 4. Workloads
The accelerator is optimized for:
- **Particle Systems**: N-body simulations.
- **Ray Tracing**: BVH traversal and intersection.
- **Audio**: 3D spatial audio convolution.
- **AI**: Simple inference (MLP/CNN) for game logic.

## 5. How to Run

### Requirements
- **Rust** (cargo)
- **Python 3** (for visualization)
- **Icarus Verilog** (for hardware simulation)

### Running the Simulator Demo
We have a particle physics demo that verifies the software stack.

```bash
python3 demo/visualizer.py
```

This will:
1. Compile the Rust Simulator.
2. Run a particle physics kernel on the simulator.
3. Capture the output.
4. Visualize the particle movement in the terminal.

### Running Hardware Verification
To verify the Verilog RTL implementation:

```bash
iverilog -g2012 -o sim hardware/tb_hansen_core.v hardware/hansen_core.v
vvp sim
```

## 6. Repository Structure
- `simulator/`: Rust-based instruction set simulator.
    - `src/core.rs`: The simulated CPU core.
    - `src/driver.rs`: Mock driver for host interaction.
- `hardware/`: Verilog RTL for FPGA implementation.
    - `hansen_core.v`: The hardware logic.
- `demo/`: Python visualization scripts.

## 7. Roadmap
- **Q1 2026**: Deploy to FPGA (Lattice iCE40).
- **Q2 2026**: Port simple "Game Engine" (Godot module) to use the accelerator.
- **Q4 2026**: Tape-out first test chip (SkyWater 130nm).

---
*Built for the future of specialized computing.*
