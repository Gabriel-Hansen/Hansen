`timescale 1ns / 1ps

// FPGA Top Level Wrapper for Hansen SoC
// Target: Digilent Arty A7-35T (XC7A35T)
// Clock: 100 MHz System Clock

module hansen_top (
    input wire clk_100mhz,  // Main Oscillator
    input wire reset_n_pin, // Active Low Reset Button
    
    // LEDs for Status
    output wire [3:0] leds,
    
    // UART (Future)
    input wire uart_rx,
    output wire uart_tx
);

    // 1. Clock Management (Optional MMCM placeholder)
    wire sys_clk = clk_100mhz; // Direct for now (100MHz is fast for this core, might need divider)
    
    // 2. Reset Conditioning
    // 2. Reset Conditioning (Synchronizer to SysClk)
    reg rst_sync_1, rst_sync_2;
    wire reset_in = ~reset_n_pin; // Active High internal
    
    always @(posedge sys_clk) begin
        rst_sync_1 <= reset_in;
        rst_sync_2 <= rst_sync_1;
    end
    
    wire reset = rst_sync_2; // Synchronized Reset

    // 3. Core Instantiation
    wire [31:0] debug_x1;
    wire trap;
    
    // Internal Memory Signals (SoC Basic)
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire        dmem_we;
    wire [31:0] dmem_rdata;

    // Instantiate Core
    hansen_core core (
        .clk(sys_clk),
        .reset(reset),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_rdata(dmem_rdata),
        .reg_x1_debug(debug_x1),
        .trap(trap)
    );
    
    // 4. Memory Block (BRAM - 2KB for FPGA Demo)
    // NOTE: IMEM and DMEM share the same BRAM for demo purposes (Unified Memory).
    // This simplifies the FPGA Top Level but is not a true Harvard architecture.

    // In real FPGA, use Xilinx IP Block Memory Generator
    // Here we interpret a simple behavioral array as Block RAM
    reg [31:0] bram [0:511];
    
    // BRAM Initialization for Bitstream
    initial begin
        $readmemh("fpga/firmware.hex", bram);
    end

    
    // Address Masking (Prevent Out-Of-Bounds)
    // Mask to 9 bits (512 words)
    wire [8:0] imem_idx = imem_addr[10:2];
    wire [8:0] dmem_idx = dmem_addr[10:2];

    assign imem_rdata = bram[imem_idx];
    assign dmem_rdata = bram[dmem_idx];
    
    always @(posedge sys_clk) begin
        if (dmem_we) bram[dmem_idx] <= dmem_wdata;
    end

    // 5. Output Logic
    // If TRAP occurs, turn ALL LEDs ON (Panic Mode)
    assign leds = trap ? 4'b1111 : debug_x1[3:0];
    
    // Stub UART (Documented Limitation)
    assign uart_tx = 1'b1; // Idle line

endmodule
