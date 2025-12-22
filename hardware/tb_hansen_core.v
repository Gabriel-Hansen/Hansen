
`timescale 1ns/1ps

module tb_hansen_core;

    reg clk;
    reg reset;
    
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire mem_we;
    reg [31:0] mem_rdata;
    
    wire [31:0] reg_x1;

    hansen_core uut (
        .clk(clk),
        .reset(reset),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_we(mem_we),
        .mem_rdata(mem_rdata),
        .reg_x1_debug(reg_x1)
    );

    // Mock Instruction Memory (just an array)
    reg [31:0] imem [0:1023];

    always #5 clk = ~clk; // 10ns clock

    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        
        // Program: Sum 1..5
        // 0: ADDI x1, x0, 0   (0x00000093)
        imem[0] = 32'h00000093;
        // 4: ADDI x2, x0, 5   (0x00500113)
        imem[1] = 32'h00500113;
        // 8: ADDI x3, x0, 1   (0x00100193)
        imem[2] = 32'h00100193;
        // 12: ADD x1, x1, x2  (0x002080b3)
        imem[3] = 32'h002080b3; 
        
        // Stop here for simple test (no branch loop yet to avoid complexity in first pass)
        
        #20 reset = 0;
        
        #200;
        $display("Final x1: %d", reg_x1);
        if (reg_x1 == 5) $display("SUCCESS: ADDI + ADD works");
        else $display("FAILURE");
        
        $finish;
    end
    
    // Memory Read Logic (Instruction Fetch)
    always @(mem_addr) begin
         mem_rdata = imem[mem_addr[31:2]]; // Word aligned
    end

endmodule
