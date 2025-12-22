
// Hansen Core - 5-Stage Pipelined RISC-V (RV32I Subset)
// Stages: IF -> ID -> EX -> MEM -> WB

module hansen_core (
    input clk,
    input reset,
    
    // Instruction Memory Interface
    output [31:0] imem_addr,
    input  [31:0] imem_rdata, // Instruction
    
    // Data Memory Interface
    output [31:0] dmem_addr,
    output [31:0] dmem_wdata,
    output        dmem_we,
    input  [31:0] dmem_rdata,
    
    // Debug
    output [31:0] reg_x1_debug
);

    // --- Registers ---
    reg [31:0] regs [0:31];
    integer k;
    
    assign reg_x1_debug = regs[1];

    // --- Stage 1: IF (Instruction Fetch) ---
    reg [31:0] pc;
    wire [31:0] pc_next;
    wire        stall;
    wire        flush;
    
    // PC Logic
    // Branch/Jump signals from EX stage
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;
    
    // Hazard Stall Signal
    wire        hazard_stall;

    always @(posedge clk or posedge reset) begin
        if (reset) pc <= 0;
        else if (!stall && !hazard_stall) begin // Stall freezes PC
            if (ex_branch_taken) pc <= ex_branch_target;
            else pc <= pc_next;
        end
    end
    
    assign imem_addr = pc;
    
    // IF/ID Pipeline Register
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 0;
            if_id_instr <= 0; // NOP
        end else if (flush) begin
            if_id_pc <= 0;
            if_id_instr <= 0; // NOP
        end else if (hazard_stall) begin
             // STALL: Keep current values (Freeze pipeline)
             if_id_pc <= if_id_pc;
             if_id_instr <= if_id_instr;
             
        end else if (!stall) begin
            if_id_pc <= pc;
            if_id_instr <= imem_rdata;
        end
    end

    // --- Stage 2: ID (Instruction Decode) ---
    wire [31:0] id_instr = if_id_instr;
    wire [4:0]  rs1_idx = id_instr[19:15];
    wire [4:0]  rs2_idx = id_instr[24:20];
    wire [4:0]  rd_idx  = id_instr[11:7];
    wire [6:0]  opcode  = id_instr[6:0];
    wire [31:0] imm_i   = {{20{id_instr[31]}}, id_instr[31:20]};
    wire [31:0] imm_s   = {{20{id_instr[31]}}, id_instr[31:25], id_instr[11:7]};
    wire [31:0] imm_b   = {{19{id_instr[31]}}, id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
    wire [31:0] imm_j   = {{12{id_instr[31]}}, id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};

    // Register Read
    wire [31:0] rs1_val = (rs1_idx == 0) ? 0 : regs[rs1_idx];
    wire [31:0] rs2_val = (rs2_idx == 0) ? 0 : regs[rs2_idx];
    
    // Control Signals
    // Simple decoding
    wire is_load  = (opcode == 7'b0000011);
    wire is_store = (opcode == 7'b0100011);
    wire is_branch= (opcode == 7'b1100011);
    wire is_jal   = (opcode == 7'b1101111);
    wire is_jalr  = (opcode == 7'b1100111); // New JALR
    wire reg_write_en = (opcode == 7'b0110011 || opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1101111 || opcode == 7'b1100111); 

    // --- HAZARD DETECTION UNIT ---
    // Detect RAW dependency: ID.rs1/rs2 == EX.rd OR MEM.rd
    // If detected, Stall Fetch/Decode, Insert NOP into Execute.
    // Note: We check ex_mem_rd (EX stage output) and mem_wb_rd (MEM stage output)
    // Actually, simplified: check id_ex_rd (EX stage current) and ex_mem_rd (MEM stage current)
    
    wire ex_hazard_rs1 = (id_ex_reg_write && id_ex_rd != 0 && id_ex_rd == rs1_idx);
    wire ex_hazard_rs2 = (id_ex_reg_write && id_ex_rd != 0 && id_ex_rd == rs2_idx);
    wire mem_hazard_rs1 = (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == rs1_idx);
    wire mem_hazard_rs2 = (ex_mem_reg_write && ex_mem_rd != 0 && ex_mem_rd == rs2_idx);
    
    assign hazard_stall = ex_hazard_rs1 || ex_hazard_rs2 || mem_hazard_rs1 || mem_hazard_rs2;

    // ID/EX Pipeline Register
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_val;
    reg [31:0] id_ex_rs2_val;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rd;
    reg [6:0]  id_ex_opcode;
    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_sub_flag; // Bit 30 for ADD/SUB distinction
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            id_ex_pc <= 0;
            id_ex_rs1_val <= 0;
            id_ex_rs2_val <= 0;
            id_ex_imm <= 0;
            id_ex_rd <= 0;
            id_ex_opcode <= 0;
            id_ex_reg_write <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_write <= 0;
            id_ex_sub_flag <= 0;
        end else if (flush || hazard_stall) begin // Insert Bubble on Hazard/Flush
            id_ex_pc <= 0;
            id_ex_rs1_val <= 0;
            id_ex_rs2_val <= 0;
            id_ex_imm <= 0;
            id_ex_rd <= 0;
            id_ex_opcode <= 0;
            id_ex_reg_write <= 0;
            id_ex_mem_read <= 0;
            id_ex_mem_write <= 0;
            id_ex_sub_flag <= 0;
        end else begin
            id_ex_pc <= if_id_pc;
            id_ex_rs1_val <= rs1_val;
            id_ex_rs2_val <= rs2_val;
            id_ex_rd <= rd_idx;
            id_ex_opcode <= opcode;
            id_ex_reg_write <= reg_write_en;
            id_ex_mem_read <= is_load;
            id_ex_mem_write <= is_store;
            id_ex_sub_flag <= id_instr[30]; // Pass bit 30
            
            // Choose Immediate based on type
            if (is_store) id_ex_imm <= imm_s;
            else if (is_branch) id_ex_imm <= imm_b;
            else if (is_jal) id_ex_imm <= imm_j;
            else id_ex_imm <= imm_i; // Default I-type/Load
        end
    end

    // --- Stage 3: EX (Execute) ---
    // ALU
    reg [31:0] alu_result;
    
    // Funct for R-Type
    wire [2:0] funct3 = id_ex_imm[14:12]; // Note: This mapping is tricky. In Pipeline, we lost raw instr. 
    // Correction: We need to pass funct3/funct7 down the pipeline or decode in ID.
    // For simplicity in this step, I'll rely on the Opcodes and simplified decoding.
    
    always @(*) begin
        case(id_ex_opcode)
            7'b0110011: begin // R-Type
                 if (id_ex_sub_flag) alu_result = id_ex_rs1_val - id_ex_rs2_val;
                 else alu_result = id_ex_rs1_val + id_ex_rs2_val;
            end
            7'b0010011: alu_result = id_ex_rs1_val + id_ex_imm;     // ADDI
            7'b0000011: alu_result = id_ex_rs1_val + id_ex_imm;     // LW Addr
            7'b0100011: alu_result = id_ex_rs1_val + id_ex_imm;     // SW Addr
            7'b1101111: alu_result = id_ex_pc + 4;                  // JAL (Store PC+4)
            7'b1100111: alu_result = id_ex_pc + 4;                  // JALR (Store PC+4)
            default:    alu_result = 0;
        endcase
    end
    
    // Branch Resolution
    wire ex_is_beq = (id_ex_opcode == 7'b1100011); 
    wire ex_is_jal = (id_ex_opcode == 7'b1101111);
    wire ex_is_jalr = (id_ex_opcode == 7'b1100111);

    wire ex_cond_met = (id_ex_rs1_val == id_ex_rs2_val); 
    
    assign ex_branch_taken = (ex_is_beq && ex_cond_met) || ex_is_jal || ex_is_jalr; 
    
    // Target Calculation
    // JAL/Branch: PC + Imm
    // JALR: RS1 + Imm
    assign ex_branch_target = (ex_is_jalr) ? (id_ex_rs1_val + id_ex_imm) : (id_ex_pc + id_ex_imm);
    
    // EX/MEM Pipeline Register
    reg [31:0] ex_mem_alu_res;
    reg [31:0] ex_mem_wdata;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
             ex_mem_alu_res <= 0;
             ex_mem_wdata <= 0;
             ex_mem_rd <= 0;
             ex_mem_reg_write <= 0;
             ex_mem_mem_read <= 0;
             ex_mem_mem_write <= 0;
        end else begin
             ex_mem_alu_res <= alu_result;
             ex_mem_wdata <= id_ex_rs2_val; // For Store
             ex_mem_rd <= id_ex_rd;
             ex_mem_reg_write <= id_ex_reg_write;
             ex_mem_mem_read <= id_ex_mem_read;
             ex_mem_mem_write <= id_ex_mem_write;
        end
    end

    // --- Stage 4: MEM (Memory Access) ---
    assign dmem_addr = ex_mem_alu_res;
    assign dmem_wdata = ex_mem_wdata;
    assign dmem_we = ex_mem_mem_write;
    
    // MEM/WB Pipeline Register
    reg [31:0] mem_wb_data;
    reg [31:0] mem_wb_alu_res;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_read;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
             mem_wb_data <= 0;
             mem_wb_alu_res <= 0;
             mem_wb_rd <= 0;
             mem_wb_reg_write <= 0;
             mem_wb_mem_read <= 0;
        end else begin
             mem_wb_data <= dmem_rdata;
             mem_wb_alu_res <= ex_mem_alu_res;
             mem_wb_rd <= ex_mem_rd;
             mem_wb_reg_write <= ex_mem_reg_write;
             mem_wb_mem_read <= ex_mem_mem_read;
        end
    end

    // --- Stage 5: WB (Write Back) ---
    wire [31:0] wb_final_data = (mem_wb_mem_read) ? mem_wb_data : mem_wb_alu_res;
    
    always @(posedge clk) begin
        if (mem_wb_reg_write && mem_wb_rd != 0) begin
            regs[mem_wb_rd] <= wb_final_data;
        end
    end

    // --- Hazard / Branch Logic (Simplified) ---
    // For this prototype, we assume no hazards (software NOPs) or stall on Load use
    // Branching: simplified to static not taken, flush if taken (not implemented fully here)
    assign pc_next = pc + 4;
    assign stall = 0;
    // Flush pipeline if branch taken
    assign flush = ex_branch_taken;
    assign pc_next = pc + 4;
    assign stall = 0; // Hazard unit needed for real FPGA

endmodule
