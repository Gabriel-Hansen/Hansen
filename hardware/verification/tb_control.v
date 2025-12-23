`timescale 1ns / 1ps

module tb_control;
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
        $dumpfile("trace_control.vcd"); $dumpvars(0, tb_control);
        for(integer i=0; i<256; i=i+1) instr_mem[i]=32'h00000013;

        // 1. BEQ Taken
        // ADDI x1, x0, 1 -> 00100093
        instr_mem[0] = 32'h00100093;
        // BEQ x1, x1, +8 -> 00108463 (Skip next instr)
        instr_mem[1] = 32'h00108463;
        // ADDI x1, x1, 1 -> 00108093 (Should stay 1 if flushed)
        instr_mem[2] = 32'h00108093;
        // Target: NOP
        
        clk=0; reset=1; #10; reset=0;
        #100;
        
        // If flush worked, x1 is still 1. If failed, x1 became 2.
        if(debug_x1 === 1) $display("[PASS] CONTROL: Branch flush successful (x1=1)");
        else begin $display("[FAIL] CONTROL: Branch flush failed (x1=%d)", debug_x1); errors++; end
        
        if(errors == 0) $display("CONTROL TESTS PASSED");
        $finish;
    end
endmodule
