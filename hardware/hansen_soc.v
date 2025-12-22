
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
    
    // DMA Signals
    wire [31:0] dma_m_addr;
    wire [31:0] dma_m_wdata;
    wire        dma_m_we;
    wire        dma_irq;
    
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

    // Instantiate DMA Controller
    // Mapped at high address or via separate bus? 
    // For simplicity: We snoop writes to 0x4000_0000 range for DMA Config
    wire dma_cfg_sel = (pcie_addr[31:28] == 4'h4); // Base 0x4...
    
    dma_controller dma (
        .clk(clk),
        .reset(reset),
        .cfg_addr(pcie_addr),
        .cfg_wdata(pcie_wdata),
        .cfg_we(pcie_we && dma_cfg_sel),
        .irq_done(dma_irq),
        .m_addr(dma_m_addr),
        .m_wdata(dma_m_wdata),
        .m_we(dma_m_we)
    );

    // Instantiate RAM (Behavioral)
    // 64KB = 16384 Words
    reg [31:0] mem [0:16383];
    
    assign ram_rdata = mem[ram_addr[15:2]]; // Word aligned read (addr / 4)

    // Bus Arbiter (Priority: DMA > PCIe > Core)
    always @(*) begin
        if (dma_m_we) begin
            ram_addr = dma_m_addr;
            ram_wdata = dma_m_wdata;
            ram_we = dma_m_we;
        end else if (pcie_we && !dma_cfg_sel) begin // Don't write to RAM if targetting DMA regs
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
