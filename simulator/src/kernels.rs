
use crate::isa::{Instruction, Opcode};

pub fn get_particle_sim_kernel() -> Vec<Instruction> {
    // A simple "particle physics" simulation kernel
    // Concept:
    // Memory [0..100]: Array of particle positions (just 1d for simplicity)
    // Goal: Apply velocity v to all positions x => x = x + v
    // Reg usage:
    // x1 = base address of positions (0)
    // x2 = velocity (constant, e.g. 2)
    // x3 = count (e.g. 10 particles)
    // x4 = current loop index (0)
    // x5 = current loaded value
    // x6 = temp for address calculation
    
    vec![
        // Init
        Instruction::new_i_type(Opcode::ADDI, 1, 0, 0),  // x1 = base addr 0
        Instruction::new_i_type(Opcode::ADDI, 2, 0, 2),  // x2 = velocity = 2
        Instruction::new_i_type(Opcode::ADDI, 3, 0, 10), // x3 = count = 10
        Instruction::new_i_type(Opcode::ADDI, 4, 0, 0),  // x4 = i = 0
        
        // Loop Start (Offset refers to instruction index relative to current PC)
        // 4: Check if i == count, if so exit
        Instruction::new_b_type(Opcode::BEQ, 4, 3, 28), // Jump to end (PC + 28 bytes = +7 instructions -> HALT)
        
        // 5: Calculate address: addr = base + i * 4 (since we use words)
        // Need to shifts or just assumes bytes? Memory is byte addressed.
        // Let's do simple byte addressing stepping by 4 manually? 
        // Or Mul... Let's use MUL if we have it, or just ADD x1 by 4 each time.
        // Let's just update base pointer x1 directly.
        
        // 5: Load x from [x1]
        Instruction::new_i_type(Opcode::LW, 5, 1, 0),
        
        // 6: Add velocity: x = x + v
        Instruction::new_r_type(Opcode::ADD, 5, 5, 2),
        
        // 7: Store x back to [x1]
        Instruction::new_s_type(Opcode::SW, 1, 5, 0),
        
        // 8: Increment pointer x1 by 4
        Instruction::new_i_type(Opcode::ADDI, 1, 1, 4),
        
        // 9: Increment counter i by 1
        Instruction::new_i_type(Opcode::ADDI, 4, 4, 1),
        
        // 10: Jump back to start (instruction 4)
        // Current PC is at index 10. verification: 4 (BEQ) is target. 
        // 10 - 4 = 6 instructions back = -24 bytes.
        Instruction::new_j_type(Opcode::JAL, 0, -24),
        
        // 11: HALT
        Instruction::new_i_type(Opcode::HALT, 0, 0, 0),
    ]
}
