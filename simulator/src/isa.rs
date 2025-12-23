
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
    UNKNOWN,
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

    pub fn decode(word: u32) -> Self {
        let opcode_bits = word & 0x7F;
        let rd  = ((word >> 7) & 0x1F) as usize;
        let funct3 = (word >> 12) & 0x7;
        let rs1 = ((word >> 15) & 0x1F) as usize;
        let rs2 = ((word >> 20) & 0x1F) as usize;
        // let funct7 = (word >> 25) & 0x7F;
        
        // I-Type Imm
        let imm_i = (word as i32) >> 20; 
        // S-Type Imm
        let imm_s = (((word as i32) >> 25) << 5) | ((word >> 7) & 0x1F) as i32;
        // B-Type Imm (complex)
        let bit_31 = (word >> 31) & 1;
        let bit_30_25 = (word >> 25) & 0x3F;
        let bit_11_8 = (word >> 8) & 0xF;
        let bit_7 = (word >> 7) & 1;
        // Extend sign from bit 31
        let imm_b_raw = (bit_31 << 12) | (bit_7 << 11) | (bit_30_25 << 5) | (bit_11_8 << 1);
        let imm_b = (imm_b_raw as i32) << 19 >> 19; // Sign extend 13 bits

        // J-Type Imm
        // imm[20|10:1|11|19:12]
        let j_bit_31 = (word >> 31) & 1;
        let j_bit_19_12 = (word >> 12) & 0xFF;
        let j_bit_20 = (word >> 20) & 1;
        let j_bit_30_21 = (word >> 21) & 0x3FF;
        let imm_j_raw = (j_bit_31 << 20) | (j_bit_19_12 << 12) | (j_bit_20 << 11) | (j_bit_30_21 << 1);
        let imm_j = (imm_j_raw as i32) << 11 >> 11; // Sign extend 21 bits

        match opcode_bits {
            0x33 => { // R-Type 0110011
                let bit_30 = (word >> 30) & 1;
                // Check bit 30 for SUB
                if bit_30 == 1 { Instruction::new_r_type(Opcode::SUB, rd, rs1, rs2) }
                else { Instruction::new_r_type(Opcode::ADD, rd, rs1, rs2) }
                // MUL is not standard R-Type check without funct7 check, simplification here.
            },
            0x13 => Instruction::new_i_type(Opcode::ADDI, rd, rs1, imm_i),
            0x03 => Instruction::new_i_type(Opcode::LW, rd, rs1, imm_i),
            0x23 => Instruction::new_s_type(Opcode::SW, rs1, rs2, imm_s),
            0x63 => { // Branch
                if funct3 == 0 { Instruction::new_b_type(Opcode::BEQ, rs1, rs2, imm_b) }
                else { Instruction::new_b_type(Opcode::BNE, rs1, rs2, imm_b) }
            },
            0x6F => Instruction::new_j_type(Opcode::JAL, rd, imm_j),
            0x7B => Instruction::new_i_type(Opcode::HALT, 0, 0, 0), // Custom
            _ => Instruction { opcode: Opcode::UNKNOWN, rd:0, rs1:0, rs2:0, imm:0 }
        }
    }
}
