`timescale 1ns / 1ps

module tb_alu;
    reg clk;
    reg reset;
    wire [31:0] imem_addr;
    reg  [31:0] imem_rdata;
    wire [31:0] dmem_addr, dmem_wdata;
    wire        dmem_we;
    reg  [31:0] dmem_rdata;
    wire [31:0] debug_x1;
    wire        trap;

    hansen_core uut (
        .clk(clk), .reset(reset),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we), .dmem_rdata(dmem_rdata),
        .reg_x1_debug(debug_x1), .trap(trap)
    );

    reg [31:0] instr_mem [0:255];
    always #5 clk = ~clk;
    always @(*) imem_rdata = instr_mem[imem_addr[9:2]];

    integer errors = 0;

    initial begin
        $dumpfile("trace_alu.vcd"); $dumpvars(0, tb_alu);
        for(integer i=0; i<256; i=i+1) instr_mem[i]=32'h00000013;
        
        // Load Vector from shared file
        $readmemh("tests/vectors/alu.hex", instr_mem);
        
        // Wait for execution
        clk=0; reset=1; #10; reset=0;
        #100;
        
        if(debug_x1 === 10) $display("[PASS] ALU: ADDI x1 = 10");
        else begin $display("[FAIL] ALU: x1 != 10"); errors++; end
        
        if(errors == 0) $display("ALU TESTS PASSED");
        $finish;
    end
endmodule
