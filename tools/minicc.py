
import sys
import re

# Hansen Mini-C Compiler
# Compiles a subset of C to Hansen Assembly
# Features: int vars, while loops, pointer access

class Compiler:
    def __init__(self, src):
        self.src = src
        self.lines = [l.strip() for l in src.split(';') if l.strip()]
        self.regs = ['x5', 'x6', 'x7', 'x8', 'x9', 'x10'] # Temp regs
        self.vars = {} # name -> reg
        self.asm = []
        
    def alloc_reg(self, varname):
        if varname in self.vars: return self.vars[varname]
        r = self.regs.pop(0)
        self.vars[varname] = r
        return r
        
    def emit(self, instr):
        self.asm.append(instr)

    def compile(self):
        self.emit("// Compiled by minicc")
        
        for line in self.lines:
            # Ptr Assignment: *ptr = val
            if line.startswith('*'):
                match = re.match(r'\*(\w+)\s*=\s*(.+)', line)
                if match:
                    ptr, val = match.groups()
                    r_ptr = self.vars[ptr]
                    # Check if val is number or var
                    if val.isdigit():
                        r_val = 'x30' # temp
                        self.emit(f"ADDI {r_val}, x0, {val}")
                    else:
                        r_val = self.vars[val]
                    self.emit(f"SW {r_ptr}, {r_val}, 0")
                    continue
            
            # Var Declaration/Assignment: int x = 5 or x = y + 1
            if '=' in line:
                line = line.replace('int ', '')
                lhs, rhs = [x.strip() for x in line.split('=')]
                
                # Allocation
                r_lhs = self.alloc_reg(lhs)
                
                # RHS parsing
                if '+' in rhs:
                    op1, op2 = [x.strip() for x in rhs.split('+')]
                    r_op1 = self.vars[op1]
                    if op2.isdigit():
                        self.emit(f"ADDI {r_lhs}, {r_op1}, {op2}")
                    else:
                        r_op2 = self.vars[op2]
                        self.emit(f"ADD {r_lhs}, {r_op1}, {r_op2}")
                elif rhs.isdigit():
                     self.emit(f"ADDI {r_lhs}, x0, {rhs}")
                else:
                     # Copy
                     r_rhs = self.vars[rhs]
                     self.emit(f"ADD {r_lhs}, x0, {r_rhs}")
            
            # While (infinite for now)
            if 'while(1)' in line:
                self.emit("loop:")

        self.emit("HALT")
        return "\n".join(self.asm)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: minicc.py <input.c>")
        sys.exit(1)
        
    with open(sys.argv[1]) as f:
        c_code = f.read()
        
    compiler = Compiler(c_code)
    asm_code = compiler.compile()
    
    print(asm_code)
    
    # Optional: Write to file
    with open(sys.argv[1].replace('.c', '.asm'), 'w') as f:
        f.write(asm_code)
