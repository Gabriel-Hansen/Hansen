# Hansen Technical Glossary

Definitions of terms used in the Hansen Architecture documentation.

## A
- **ALU (Arithmetic Logic Unit)**: Digital circuit that performs integer arithmetic and bitwise logic values.
- **ASIC (Application-Specific Integrated Circuit)**: Customized IC for a particular use, as opposed to general-purpose FPas.

## B
- **Branch Prediction**: Mechanism to guess the outcome of a conditional operation (e.g. `If-Else`) to keep the pipeline full. Hansen v1.0 uses *Static Prediction (Not-Taken)*.

## C
- **CPI (Cycles Per Instruction)**: Average number of clock cycles per instruction. Ideal is 1.0. Hansen varies (1.0 for ALU, >1 for Load/Branch).
- **CSR (Control Status Register)**: Special registers for system configuration.

## D
- **DMA (Direct Memory Access)**: Feature allowing hardware subsystems to access main system memory independently of the CPU.
- **Driver**: Software interface that bridges the OS kernel and the hardware device.

## F
- **FPGA (Field-Programmable Gate Array)**: Integrated circuit designed to be configured by a customer or a designer after manufacturing.
- **Forwarding (Operand)**: Optimization to pass ALU results directly to the next instruction input, bypassing the Register File writeback stage.

## H
- **Hazard**: Condition where the pipeline cannot execute the next instruction in the following clock cycle.
    - **RAW (Read-After-Write)**: True dependency.
    - **Control**: Branching decision latency.
    - **Structural**: Resource conflict (e.g. Memory port busy).

## I
- **IPC (Instructions Per Cycle)**: Inverse of CPI. Throughput metric.
- **ISA (Instruction Set Architecture)**: Abstract model of a computer, defining opcodes, registers, and memory model.

## R
- **RISC-V**: Open standard instruction set architecture (ISA) based on established reduced instruction set computer principles.
- **RTL (Register Transfer Level)**: Design abstraction which models a synchronous digital circuit in terms of the flow of digital signals between hardware registers.

## S
- **Stall**: Pausing the pipeline stages to resolve a hazard.
- **Synthesis**: Process of transforming RTL code into a gate-level netlist.

## T
- **Testbench**: Verilog environment used to verify the functional correctness of a design by simulating stimulus.
- **Trap**: Synchronous exception (error) produced by the CPU (e.g. Invalid Opcode).
