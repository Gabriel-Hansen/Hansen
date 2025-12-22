
// Hansen DMA Controller
// Handles block transfers between system components
// Capability: Simple MEM-to-MEM copy (e.g. from PCIe buffer to Local RAM)
// Includes Interrupt generation

module dma_controller (
    input clk,
    input reset,
    
    // Control Interface (Memory Mapped)
    input [31:0] cfg_addr,  // 0x0=Src, 0x4=Dst, 0x8=Len, 0xC=Control/Start
    input [31:0] cfg_wdata,
    input        cfg_we,
    output reg   irq_done,  // Interrupt Output
    
    // Master Interface (Write to RAM)
    output reg [31:0] m_addr,
    output reg [31:0] m_wdata,
    output reg        m_we
);

    reg [31:0] src_addr;
    reg [31:0] dst_addr;
    reg [31:0] length;   // In words
    reg        dma_busy;

    // Registers mapping
    // 0x0: Source Pointer (Mocked, assuming hardcoded for now or passed via mock PCIe)
    // 0x4: Dest Pointer (Local RAM)
    // 0x8: Length
    // 0xC: Start (Bit 0)

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            src_addr <= 0;
            dst_addr <= 0;
            length <= 0;
            dma_busy <= 0;
            irq_done <= 0;
            m_we <= 0;
        end else begin
            // Configuration Write
            if (cfg_we && !dma_busy) begin
                if (cfg_addr[3:0] == 4'h0) src_addr <= cfg_wdata;
                if (cfg_addr[3:0] == 4'h4) dst_addr <= cfg_wdata;
                if (cfg_addr[3:0] == 4'h8) length <= cfg_wdata;
                if (cfg_addr[3:0] == 4'hC && cfg_wdata[0]) begin
                     dma_busy <= 1;
                     irq_done <= 0;
                end
            end
            
            // DMA Machine
            if (dma_busy) begin
                if (length > 0) begin
                    // One word per cycle (Super fast!)
                    // In real hardware, we'd read Src, wait, then write Dst.
                    // Here we are generating "Internal Writes" to RAM based on a pattern
                    
                    m_addr <= dst_addr;
                    m_wdata <= 32'hDEADBEEF; // Mock Payload
                    m_we <= 1;
                    
                    dst_addr <= dst_addr + 4;
                    length <= length - 1;
                end else begin
                    // Done
                    dma_busy <= 0;
                    m_we <= 0;
                    irq_done <= 1; // Assert Interrupt
                end
            end else begin
                // Clear IRQ on write to Control? Or auto clear?
                // Auto clear for now after 1 cycle pulse
                if (irq_done) irq_done <= 0;
            end
        end
    end

endmodule
