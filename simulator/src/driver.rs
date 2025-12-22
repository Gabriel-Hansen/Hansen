// Driver Mock
// Acts as the interface between User Space (Application) and "Hardware" (Simulator Core)
// In a real scenario, this would be a kernel module or a user-space library wrapping ioctls.

use crate::core::Core;
use crate::memory::Memory;
use crate::isa::Instruction;

pub struct AcceleratorDriver {
    pub memory: Memory,
    pub core: Core,
}

pub struct PerfStats {
    pub core_cycles: u64,
}

impl AcceleratorDriver {
    pub fn new() -> Self {
        AcceleratorDriver {
            // Initialize hardware with 64KB memory and 10 cycle latency
            memory: Memory::new(65536, 10),
            core: Core::new(0),
        }
    }

    // "ioctl"-like command to load data into device memory
    // In a real PCIe device, this would be DMA
    pub fn copy_to_device(&mut self, data: &[u8], addr: usize) -> Result<(), String> {
         if addr + data.len() > self.memory.size {
             return Err("DMA out of bounds".to_string());
         }
         for (i, &byte) in data.iter().enumerate() {
             self.memory.data[addr + i] = byte;
         }
         Ok(())
    }

    // Submit a kernel (command buffer) for execution
    pub fn submit_kernel(&mut self, kernel: Vec<Instruction>) -> Result<PerfStats, String> {
        // Reset core state for new execution (except maybe general memory)
        self.core.pc = 0;
        self.core.halted = false;
        self.core.cycle_count = 0;
        self.core.regs = [0; 32];

        // In this mock, we execute synchronously.
        // In real driver, this would return immediately and we'd wait for interrupt.
        
        let max_cycles = 100_000; // Watchdog
        while !self.core.halted && self.core.cycle_count < max_cycles {
             self.core.step(&kernel, &mut self.memory)?;
        }

        if !self.core.halted {
            return Err("Watchdog timer expired: Kernel took too long".to_string());
        }

        Ok(PerfStats { core_cycles: self.core.cycle_count })
    }

    pub fn read_register(&self, reg_idx: usize) -> i32 {
        if reg_idx == 0 { 0 } else { self.core.regs[reg_idx] }
    }
    
    pub fn get_perf_stats(&self) -> u64 {
        self.core.cycle_count
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::isa::Opcode;

    #[test]
    fn test_driver_lifecycle() {
        let mut driver = AcceleratorDriver::new();
        
        // 1. Initial State
        assert_eq!(driver.core.halted, false);
        assert_eq!(driver.core.cycle_count, 0);

        // 2. Submit Kernel (ADDI x1, x0, 10; HALT)
        // This implicitly tests transition to RUNNING and back to HALTED locally
        let kernel = vec![
            Instruction { opcode: Opcode::ADDI, rd: 1, rs1: 0, rs2: 0, imm: 10 },
            Instruction { opcode: Opcode::HALT, rd: 0, rs1: 0, rs2: 0, imm: 0 },
        ];
        
        let res = driver.submit_kernel(kernel);
        assert!(res.is_ok());

        // 3. Post-Execution State
        assert_eq!(driver.core.halted, true);
        assert_eq!(driver.core.regs[1], 10);
        assert!(driver.get_perf_stats() > 0);
    }
}
