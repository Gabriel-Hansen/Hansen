`timescale 1ns / 1ps

module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input        funct7_5, // Instruction bit 30
    
    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       branch,
    output reg       is_jal,
    output reg       is_jalr,
    output reg       alu_sub_flag,
    output reg       alu_slt_flag,
    output reg       trap
);

    always @(*) begin
        // Defaults
        reg_write = 0;
        mem_read  = 0;
        mem_write = 0;
        branch    = 0;
        is_jal    = 0;
        is_jalr   = 0;
        alu_sub_flag = 0;
        alu_slt_flag = 0;
        trap      = 0;

        case (opcode)
            7'b0110011: begin // R-Type (ADD, SUB, SLT, MUL)
                reg_write = 1;
                // Check Funct7 bit 30 for SUB
                if (funct7_5) alu_sub_flag = 1;
                // Check Funct3 for SLT
                if (funct3 == 3'b010) alu_slt_flag = 1;
            end
            
            7'b0010011: begin // I-Type (ADDI, NOP)
                reg_write = 1;
            end
            
            7'b0000011: begin // Load (LW)
                reg_write = 1;
                mem_read  = 1;
            end
            
            7'b0100011: begin // Store (SW)
                mem_write = 1;
            end
            
            7'b1100011: begin // Branch (BEQ)
                branch = 1;
            end
            
            7'b1101111: begin // JAL
                reg_write = 1;
                is_jal    = 1;
            end
            
            7'b1100111: begin // JALR
                reg_write = 1;
                is_jalr   = 1;
            end
            
            7'b1111011: begin // HALT (Custom)
                // Halt logic often handled externally or via trap, 
                // but let's treat it as valid instruction that triggers system Stop.
                // For now, standard core logic doesn't trap on HALT, but Driver might.
                // ISA_REFERENCE says HALT triggers IRQ.
                // We mark it not-trap here so it doesn't count as "Illegal Opcode".
            end

            default: begin
                // Illegal Opcode
                // Note: Opcode 0 (Reset state) falls here!
                trap = 1; 
            end
        endcase
    end

endmodule
