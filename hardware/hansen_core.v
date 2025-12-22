
// Hansen Core - Simplified RISC-V (RV32I Subset)
// Single cycle implementation for demonstration/simulation

module hansen_core (
    input clk,
    input reset,
    
    // Memory Interface
    output [31:0] mem_addr,
    output [31:0] mem_wdata,
    output        mem_we,    // Write Enable
    input  [31:0] mem_rdata, // Read Data from memory
    
    // Debug
    output [31:0] reg_x1_debug
);

    // Instruction Decode Fields
    wire [31:0] instruction = mem_rdata; // Simple fetch: assumes Mem read is instant/latched for instruction
    // Note: In real Single Cycle, we need Instruction Memory and Data Memory separate or Harvard.
    // Here we will cheat slightly for Phase 3 and assume "instruction" comes from an Instruction Memory 
    // and "mem_rdata" comes from Data Memory. 
    // But to keep it simple, let's just make it a pure processor logic unit that requests instructions.
    
    // PC Logic
    reg [31:0] pc;
    reg [31:0] next_pc;

    // Registers (x0-x31)
    reg [31:0] regs [0:31];
    integer i;
    
    assign reg_x1_debug = regs[1];
    
    // Fetch PC
    assign mem_addr = pc; 
    
    // We need a specific Instruction Memory interface if we want single cycle Von Neumann without stalls.
    // For now, let's assume Harvard architecture interface in the testbench.
    // Port A: Instruction Fetch (PC -> Instruction)
    // Port B: Data Access (ALU Result -> Data)
    // To solve this in one module, let's expose two interfaces? 
    // Or just fetch instruction at posedge and execute next cycle?
    // Let's stick to simple "Fetch -> Decode -> Execute" state machine or simple single cycle.
    
    // Let's implement a very simple state machine:
    // FETCH -> EXECUTE
    
    reg [1:0] state;
    localparam STATE_FETCH = 0;
    localparam STATE_EXEC = 1;
    
    // Instruction fields
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];
    
    // Immediates
    wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

    // ALU Signals
    reg [31:0] alu_in1, alu_in2;
    wire [31:0] alu_result = alu_in1 + alu_in2; // Very temporary simplified ALU
    // We need real ALU logic:
    reg [31:0] alu_out;
    
    // Data Memory Interface
    assign mem_wdata = regs[rs2];
    assign mem_we = (state == STATE_EXEC && opcode == 7'b0100011); // SW
    
    always @(*) begin
        alu_in1 = (rs1 == 0) ? 0 : regs[rs1];
        // ALU source 2 Mux
        if (opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b0100011) begin // ADDI, LW, SW
             alu_in2 = (opcode == 7'b0100011) ? imm_s : imm_i; // SW uses S-imm, others I-imm
        end else begin
             alu_in2 = (rs2 == 0) ? 0 : regs[rs2];
        end
        
        case(opcode)
            7'b0110011: begin // R-Type (ADD, SUB)
                 if (funct7[5]) alu_out = alu_in1 - alu_in2; // SUB
                 else alu_out = alu_in1 + alu_in2; // ADD
            end
            7'b0010011: alu_out = alu_in1 + imm_i; // ADDI
            default: alu_out = 0;
        endcase
    end

    // Sequential Logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            state <= STATE_FETCH;
            for (i=0; i<32; i=i+1) regs[i] <= 0;
        end else begin
            case (state)
                STATE_FETCH: begin
                    // Mem addr is already PC. Data comes back next cycle?
                    // Assuming synchronous memory, data is available at posedge.
                    // If asynchronous, available now.
                    // Let's assume we wait a cycle.
                    state <= STATE_EXEC;
                end
                STATE_EXEC: begin
                    // Execute based on currently available 'instruction' (mem_rdata)
                    // (Assuming mem_rdata holds the instruction from PC address)
                    
                    reg [31:0] pc_jump;
                    pc_jump = pc + 4; // Default next
                    
                    case (opcode)
                        7'b0110011: begin // R-Type
                             if (rd != 0) regs[rd] <= alu_out;
                        end
                        7'b0010011: begin // ADDI
                             if (rd != 0) regs[rd] <= alu_out;
                        end
                        7'b1100011: begin // Branch (BEQ)
                             // Simple BEQ only for now
                             // funct3 000 = BEQ
                             if (funct3 == 3'b000) begin 
                                 if (regs[rs1] == regs[rs2]) pc_jump = pc + imm_b;
                             end
                        end
                        // LW, SW etc not fully implemented in this minimalist snippet for now
                    endcase
                    
                    pc <= pc_jump;
                    state <= STATE_FETCH;
                end
            endcase
        end
    end

endmodule
