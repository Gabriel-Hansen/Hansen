
import sys
import struct

# Simple Hansen Assembler
# Converts .asm text file to .bin machine code

OPCODES = {
    'ADD': 0x33, 'SUB': 0x33, # R-Type
    'LW': 0x03,  'SW': 0x23,  # I/S Type
    'ADDI': 0x13,
    'BEQ': 0x63, 'JAL': 0x6F,
    'HALT': 0x7F # Custom
}

FUNCT3 = {
    'ADD': 0, 'SUB': 0,
    'LW': 2, 'SW': 2,
    'ADDI': 0,
    'BEQ': 0,
}

def parse_reg(r):
    if not r.startswith('x'): raise ValueError("Invalid register " + r)
    return int(r[1:])

def encode_r_type(opcode, funct3, funct7, rd, rs1, rs2):
    # | funct7 (7) | rs2 (5) | rs1 (5) | funct3 (3) | rd (5) | opcode (7) |
    val = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return val

def encode_i_type(opcode, funct3, rd, rs1, imm):
    # | imm[11:0] (12) | rs1 (5) | funct3 (3) | rd (5) | opcode (7) |
    if imm < 0: imm = (1 << 12) + imm
    val = ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    return val

def main():
    if len(sys.argv) < 3:
        print("Usage: assembler.py <input.asm> <output.bin>")
        return

    lines = open(sys.argv[1]).readlines()
    binary = bytearray()

    print(f"Assembling {sys.argv[1]}...")

    for line in lines:
        line = line.split('//')[0].strip() # Remove comments
        if not line or line.endswith(':'): continue 
        
        parts = line.replace(',', ' ').split()
        op = parts[0].upper()
        
        instr_bytes = 0
        
        if op == 'ADD':
            rd, rs1, rs2 = map(parse_reg, parts[1:4])
            instr_bytes = encode_r_type(OPCODES['ADD'], 0, 0, rd, rs1, rs2)
        elif op == 'ADDI':
            rd, rs1 = map(parse_reg, parts[1:3])
            imm = int(parts[3])
            instr_bytes = encode_i_type(OPCODES['ADDI'], 0, rd, rs1, imm)
        elif op == 'HALT':
             instr_bytes = 0x0000007F
        
        # Output Little Endian
        binary.extend(struct.pack('<I', instr_bytes))

    with open(sys.argv[2], 'wb') as f:
        f.write(binary)
    
    print(f"Done. Wrote {len(binary)} bytes to {sys.argv[2]}")

if __name__ == '__main__':
    main()
