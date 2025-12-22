# Hansen ISA Reference Definitions v1.0

This document formally defines the Instruction Set Architecture (ISA) for the Hansen Accelerator.
It strictly adheres to **RV32I (Base Integer Instruction Set)** conventions where applicable, with custom extensions for accelerator control.

---

## 1. Machine Model

- **Word Size**: 32-bit (4 bytes)
- **Endianness**: Little Endian
- **Registers**:
  - `x0` (Zero): Hardwired to 0.
  - `x1` - `x31`: General Purpose Registers (GPR).
  - `PC`: Program Counter.

## 2. Instruction Formats

The Hansen Core uses standard RISC-V 32-bit fixed-length instruction formats.

| Type | 31 ... 25 | 24 ... 20 | 19 ... 15 | 14 ... 12 | 11 ... 7 | 6 ... 0 |
|---|---|---|---|---|---|---|
| **R-Type** | funct7 | rs2 | rs1 | funct3 | rd | opcode |
| **I-Type** | imm[11:0] | rs1 | funct3 | rd | opcode |
| **S-Type** | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
| **B-Type** | imm[12\|10:5] | rs2 | rs1 | funct3 | imm[4:1\|11] | opcode |
| **J-Type** | imm[20\|10:1\|11\|19:12] | | | | rd | opcode |

---

## 3. Instruction Encoding Map

### 3.1 Arithmetic & Logic (R-Type / I-Type)
- **Opcode**: `0010011` (Immediate), `0110011` (Register)

| Mnemonic | Format | Opcode | Funct3 | Funct7 | Description |
|---|---|---|---|---|---|
| **ADD** | R | `0110011` | `000` | `0000000` | rd = rs1 + rs2 |
| **SUB** | R | `0110011` | `000` | `0100000` | rd = rs1 - rs2 |
| **ADDI** | I | `0010011` | `000` | N/A | rd = rs1 + imm |
| **MUL** | R | `0110011` | `000` | `0000001` | rd = rs1 * rs2 (M-Ext subset) |

### 3.2 Memory Access (Load/Store)
- **Load Opcode**: `0000011`
- **Store Opcode**: `0100011`

| Mnemonic | Format | Opcode | Funct3 | Description |
|---|---|---|---|---|
| **LW** | I | `0000011` | `010` | rd = Mem[rs1 + imm] (Word) |
| **SW** | S | `0100011` | `010` | Mem[rs1 + imm] = rs2 (Word) |

### 3.3 Control Flow (Branch/Jump)
- **Branch Opcode**: `1100011`
- **JAL Opcode**: `1101111`
- **JALR Opcode**: `1100111` (Essential for `ret`)

| Mnemonic | Format | Opcode | Funct3 | Description |
|---|---|---|---|---|
| **BEQ** | B | `1100011` | `000` | if (rs1 == rs2) PC += imm |
| **BNE** | B | `1100011` | `001` | if (rs1 != rs2) PC += imm |
| **JAL** | J | `1101111` | N/A | rd = PC+4; PC += imm |
| **JALR** | I | `1100111` | `000` | rd = PC+4; PC = (rs1 + imm) & ~1 |

### 3.4 System / Custom
- **Custom Opcode**: `1111011` (Custom-0 Reserved space in RISC-V)

| Mnemonic | Format | Opcode | Funct3 | Description |
|---|---|---|---|---|
| **HALT** | I | `1111011` | `000` | Stop execution. Trigger IRQ 1. |

---

## 4. Hardware Constraints
- **Address Space**: 0x00000000 - 0xFFFFFFFF
- **Implemented RAM**: Base 0x00000000, Size 64KB.
- **Unaligned Access**: Not supported. All access must be 4-byte aligned.

## 5. Control Signal Truth Table
To ensure FPGA synthesis safety, the Control Unit follows this logic:

| Instr | Opcode | RegWrite | MemRead | MemWrite | ALUOp | Branch |
|---|---|---|---|---|---|---|
| **R-Type** | 0110011 | 1 | 0 | 0 | FUNC | 0 |
| **LW** | 0000011 | 1 | 1 | 0 | ADD | 0 |
| **SW** | 0100011 | 0 | 0 | 1 | ADD | 0 |
| **BEQ** | 1100011 | 0 | 0 | 0 | SUB | 1 |
| **JAL** | 1101111 | 1 | 0 | 0 | X | 1 |
| **JALR** | 1100111 | 1 | 0 | 0 | ADD | 1 |
