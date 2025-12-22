
// Memory Model with simulated latency

pub struct Memory {
    pub data: Vec<u8>,
    pub size: usize,
    pub latency_cycles: u32,
}

impl Memory {
    pub fn new(size: usize, latency: u32) -> Self {
        Memory {
            data: vec![0; size],
            size,
            latency_cycles: latency,
        }
    }

    pub fn read_word(&self, addr: usize) -> Result<u32, String> {
        if addr + 4 > self.size {
            return Err(format!("Memory read out of bounds: 0x{:08x}", addr));
        }
        let b0 = self.data[addr] as u32;
        let b1 = self.data[addr + 1] as u32;
        let b2 = self.data[addr + 2] as u32;
        let b3 = self.data[addr + 3] as u32;
        // Little-endian
        Ok(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
    }

    pub fn write_word(&mut self, addr: usize, value: u32) -> Result<(), String> {
        if addr + 4 > self.size {
            return Err(format!("Memory write out of bounds: 0x{:08x}", addr));
        }
        self.data[addr] = (value & 0xFF) as u8;
        self.data[addr + 1] = ((value >> 8) & 0xFF) as u8;
        self.data[addr + 2] = ((value >> 16) & 0xFF) as u8;
        self.data[addr + 3] = ((value >> 24) & 0xFF) as u8;
        Ok(())
    }
}
