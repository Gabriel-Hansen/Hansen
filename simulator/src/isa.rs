
// Instruction Set Architecture (ISA) Definition
// Based on a simplified RISC-V (RV32I) subset

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Opcode {
    ADD,
    SUB,
    MUL, // Optional M-extension
    DIV,
    ADDI,
    LW,  // Load Word
    SW,  // Store Word
    BEQ, // Branch if Equal
    BNE, // Branch if Not Equal
    JAL, // Jump and Link
    HALT, // Custom instruction to stop execution
}

#[derive(Debug, Clone, Copy)]
pub struct Instruction {
    pub opcode: Opcode,
    pub rd:  usize, // Destination register
    pub rs1: usize, // Source register 1
    pub rs2: usize, // Source register 2
    pub imm: i32,   // Immediate value
}

impl Instruction {
    pub fn new_r_type(opcode: Opcode, rd: usize, rs1: usize, rs2: usize) -> Self {
        Instruction { opcode, rd, rs1, rs2, imm: 0 }
    }

    pub fn new_i_type(opcode: Opcode, rd: usize, rs1: usize, imm: i32) -> Self {
        Instruction { opcode, rd, rs1, rs2: 0, imm }
    }

    pub fn new_s_type(opcode: Opcode, rs1: usize, rs2: usize, imm: i32) -> Self {
        // Store: rs2 is source of data using 'rs2' field, rs1 is base. imm is offset.
        Instruction { opcode, rd: 0, rs1, rs2, imm }
    }

    pub fn new_b_type(opcode: Opcode, rs1: usize, rs2: usize, imm: i32) -> Self {
        Instruction { opcode, rd: 0, rs1, rs2, imm }
    }

    pub fn new_j_type(opcode: Opcode, rd: usize, imm: i32) -> Self {
        Instruction { opcode, rd, rs1: 0, rs2: 0, imm }
    }
}
