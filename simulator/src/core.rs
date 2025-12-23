
// Core Simulation Unit

use crate::isa::{Instruction, Opcode};
use crate::memory::Memory;

pub const REG_COUNT: usize = 32;

pub struct Core {
    pub id: usize,
    pub pc: usize, // Program Counter
    pub regs: [i32; REG_COUNT],
    pub cycle_count: u64,
    pub halted: bool,
}

impl Core {
    pub fn new(id: usize) -> Self {
        Core {
            id,
            pc: 0,
            regs: [0; REG_COUNT],
            cycle_count: 0,
            halted: false,
        }
    }

    // Helper to get register value (x0 is always 0)
    fn get_reg(&self, idx: usize) -> i32 {
        if idx == 0 { 0 } else { self.regs[idx] }
    }

    fn set_reg(&mut self, idx: usize, val: i32) {
        if idx != 0 {
            self.regs[idx] = val;
        }
    }

    // Execute a single step (fetch (simulated), decode (simulated), execute)
    // In this simple simulator, 'program' is passed directly as a slice of Instructions
    pub fn step(&mut self, program: &[Instruction], memory: &mut Memory) -> Result<(), String> {
        if self.halted {
            return Ok(());
        }

        // Fetch (simulated)
        // We assume program is loaded at address 0 conceptually for instruction indexing
        // PC is byte address, so index is pc / 4
        let instruction_idx = self.pc / 4;
        if instruction_idx >= program.len() {
            return Err(format!("PC out of bounds: {}", self.pc));
        }
        let instr = program[instruction_idx];

        // Execute
        self.cycle_count += 1; // Base cycle cost

        // Branch target logic
        let mut next_pc = self.pc + 4;

        match instr.opcode {
            Opcode::ADD => {
                let val = self.get_reg(instr.rs1).wrapping_add(self.get_reg(instr.rs2));
                self.set_reg(instr.rd, val);
            }
            Opcode::SUB => {
                let val = self.get_reg(instr.rs1).wrapping_sub(self.get_reg(instr.rs2));
                self.set_reg(instr.rd, val);
            }
            Opcode::MUL => {
                let val = self.get_reg(instr.rs1).wrapping_mul(self.get_reg(instr.rs2));
                self.set_reg(instr.rd, val);
                self.cycle_count += 2; // Extra cost for MUL
            }
            Opcode::DIV => {
                 let divisor = self.get_reg(instr.rs2);
                 if divisor == 0 {
                     return Err("Division by zero".to_string());
                 }
                 let val = self.get_reg(instr.rs1).wrapping_div(divisor);
                 self.set_reg(instr.rd, val);
                 self.cycle_count += 10; // Extra cost for DIV
            }
            Opcode::ADDI => {
                let val = self.get_reg(instr.rs1).wrapping_add(instr.imm);
                self.set_reg(instr.rd, val);
            }
            Opcode::LW => {
                let addr = (self.get_reg(instr.rs1).wrapping_add(instr.imm)) as usize;
                match memory.read_word(addr) {
                    Ok(val) => {
                        self.set_reg(instr.rd, val as i32);
                        self.cycle_count += memory.latency_cycles as u64;
                    },
                    Err(e) => return Err(e),
                }
            }
            Opcode::SW => {
                let addr = (self.get_reg(instr.rs1).wrapping_add(instr.imm)) as usize;
                let val = self.get_reg(instr.rs2) as u32;
                match memory.write_word(addr, val) {
                    Ok(_) => self.cycle_count += memory.latency_cycles as u64,
                    Err(e) => return Err(e),
                }
            }
            Opcode::BEQ => {
                if self.get_reg(instr.rs1) == self.get_reg(instr.rs2) {
                    next_pc = (self.pc as i32).wrapping_add(instr.imm) as usize;
                }
            }
            Opcode::BNE => {
                if self.get_reg(instr.rs1) != self.get_reg(instr.rs2) {
                    next_pc = (self.pc as i32).wrapping_add(instr.imm) as usize;
                }
            }
            Opcode::JAL => {
                self.set_reg(instr.rd, (self.pc + 4) as i32);
                next_pc = (self.pc as i32).wrapping_add(instr.imm) as usize;
            }
            Opcode::HALT => {
                self.halted = true;
            }
            Opcode::UNKNOWN => {
                return Err(format!("Illegal Opcode at PC={}", self.pc));
            }
        }

        self.pc = next_pc;
        Ok(())
    }
}
