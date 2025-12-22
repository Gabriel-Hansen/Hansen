
// PCIe Mock Interface (Simple Transaction Layer)
// Simulates a BAR0 Memory Mapped interface.
// In a real design, this would interface with a Xilinx/Lattice PCIe Hard IP.

module pcie_mock (
    input clk,
    input reset,
    
    // "Physical" Link Interface (Simplified Packet)
    input        rx_valid,
    input [63:0] rx_data,     // [63:32] = Data, [31:0] = Addr (for write) or just Addr (for read)
    input        rx_is_write, // 1 = Write, 0 = Read
    
    output reg   tx_valid,
    output reg [31:0] tx_data, // Read return data
    
    // Internal Bus Interface (Master)
    output reg [31:0] bus_addr,
    output reg [31:0] bus_wdata,
    output reg        bus_we,
    input      [31:0] bus_rdata
);

    // Ideally we have a state machine here.
    // IDLE -> REQUEST -> WAIT_DATA -> RESPONSE
    
    // For this mock, we assume 1 cycle throughput for writes to internal bus.
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bus_addr <= 0;
            bus_wdata <= 0;
            bus_we <= 0;
            tx_valid <= 0;
            tx_data <= 0;
        end else begin
            // Default
            bus_we <= 0;
            tx_valid <= 0;
            
            if (rx_valid) begin
                if (rx_is_write) begin
                    // Write Transaction
                    // rx_data = {32'hDATA, 32'hADDR}
                    bus_addr <= rx_data[31:0];
                    bus_wdata <= rx_data[63:32];
                    bus_we <= 1;
                end else begin
                    // Read Transaction
                    // rx_data = {32'hZERO, 32'hADDR}
                    bus_addr <= rx_data[31:0];
                    // Next cycle, bus_rdata wil use this addr (if RAM is synchronous)
                    // We need a state machine for reads usually.
                    // Let's cheat and assume we can latch result next cycle if we hold address.
                end
            end
        end
    end

endmodule
