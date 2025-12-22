
// Hansen SoC Top Level
// Connects Core + PCIe Mock + Shared RAM

module hansen_soc (
    input clk,
    input reset,
    
    // External PCIe Link
    input        pcie_rx_valid,
    input [63:0] pcie_rx_data,
    input        pcie_rx_is_write,
    output       pcie_tx_valid,
    output [31:0] pcie_tx_data
);

    // Bus Signals
    wire [31:0] core_addr;
    wire [31:0] core_wdata;
    wire        core_we;
    wire [31:0] core_rdata;
    
    wire [31:0] pcie_addr;
    wire [31:0] pcie_wdata;
    wire        pcie_we;
    // wire [31:0] pcie_rdata; // Not used yet for readback
    
    // RAM Signals (Arbitrated)
    reg [31:0] ram_addr;
    reg [31:0] ram_wdata;
    reg        ram_we;
    wire [31:0] ram_rdata;

    // Instantiate Core
    hansen_core cpu (
        .clk(clk),
        .reset(reset),
        .mem_addr(core_addr),
        .mem_wdata(core_wdata),
        .mem_we(core_we),
        .mem_rdata(core_rdata), // Connects to Shared RAM Read
        .reg_x1_debug()
    );

    // Instantiate PCIe
    pcie_mock pcie (
        .clk(clk),
        .reset(reset),
        .rx_valid(pcie_rx_valid),
        .rx_data(pcie_rx_data),
        .rx_is_write(pcie_rx_is_write),
        .tx_valid(pcie_tx_valid),
        .tx_data(pcie_tx_data),
        .bus_addr(pcie_addr),
        .bus_wdata(pcie_wdata),
        .bus_we(pcie_we),
        .bus_rdata(ram_rdata) // Shared read
    );

    // Instantiate RAM (Behavioral)
    // 64KB = 16384 Words
    reg [31:0] mem [0:16383];
    
    assign ram_rdata = mem[ram_addr[15:2]]; // Word aligned read (addr / 4)

    // Bus Arbiter (Priority: PCIe > Core)
    // If PCIe is writing, it takes control. Otherwise Core has control.
    always @(*) begin
        if (pcie_we) begin
            ram_addr = pcie_addr;
            ram_wdata = pcie_wdata;
            ram_we = pcie_we;
        end else begin
            ram_addr = core_addr;
            ram_wdata = core_wdata;
            ram_we = core_we;
        end
    end

    // RAM Write Process
    always @(posedge clk) begin
        if (ram_we) begin
            mem[ram_addr[15:2]] <= ram_wdata;
        end
    end
    
    // Connect Read Data back to Core
    assign core_rdata = ram_rdata;

endmodule
