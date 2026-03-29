module AES_AXI_Core #
(
    parameter integer C_S00_AXI_DATA_WIDTH   = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH   = 5,
    parameter integer C_S00_AXIS_TDATA_WIDTH = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH = 32,
    parameter integer C_M00_AXIS_START_COUNT = 32
)
(
    // AXI-Lite
    input  wire        s00_axi_aclk,
    input  wire        s00_axi_aresetn,
    input  wire [4:0]  s00_axi_awaddr,
    input  wire [2:0]  s00_axi_awprot,
    input  wire        s00_axi_awvalid,
    output wire        s00_axi_awready,
    input  wire [31:0] s00_axi_wdata,
    input  wire [3:0]  s00_axi_wstrb,
    input  wire        s00_axi_wvalid,
    output wire        s00_axi_wready,
    output wire [1:0]  s00_axi_bresp,
    output wire        s00_axi_bvalid,
    input  wire        s00_axi_bready,
    input  wire [4:0]  s00_axi_araddr,
    input  wire [2:0]  s00_axi_arprot,
    input  wire        s00_axi_arvalid,
    output wire        s00_axi_arready,
    output wire [31:0] s00_axi_rdata,
    output wire [1:0]  s00_axi_rresp,
    output wire        s00_axi_rvalid,
    input  wire        s00_axi_rready,

    // AXI-Stream Slave
    input  wire        s00_axis_aclk,
    input  wire        s00_axis_aresetn,
    output wire        s00_axis_tready,
    input  wire [31:0] s00_axis_tdata,
    input  wire [3:0]  s00_axis_tstrb,
    input  wire        s00_axis_tlast,
    input  wire        s00_axis_tvalid,

    // AXI-Stream Master
    input  wire        m00_axis_aclk,
    input  wire        m00_axis_aresetn,
    output wire        m00_axis_tvalid,
    output wire [31:0] m00_axis_tdata,
    output wire [3:0]  m00_axis_tstrb,
    output wire        m00_axis_tlast,
    input  wire        m00_axis_tready
);
    
    // Internal Wires
    wire [127:0] aes_key, aes_counter, aes_plaintext, aes_ciphertext;
    wire         aes_start, aes_done, m_busy;

    AES_AXI_Core_slave_lite_v1_0_S00_AXI inst_lite (
        .o_aes_key(aes_key),
        .o_aes_counter(aes_counter),
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    AES_AXI_Core_slave_stream_v1_0_S00_AXIS inst_s_stream (
        .o_aes_plaintext(aes_plaintext),
        .o_aes_start(aes_start),
        .i_aes_ready(!m_busy),
        .S_AXIS_ACLK(s00_axis_aclk),
        .S_AXIS_ARESETN(s00_axis_aresetn),
        .S_AXIS_TREADY(s00_axis_tready),
        .S_AXIS_TDATA(s00_axis_tdata),
        .S_AXIS_TSTRB(s00_axis_tstrb),
        .S_AXIS_TLAST(s00_axis_tlast),
        .S_AXIS_TVALID(s00_axis_tvalid)
    );

    AES_AXI_Core_master_stream_v1_0_M00_AXIS inst_m_stream (
        .i_aes_ciphertext(aes_ciphertext),
        .i_aes_done(aes_done),
        .o_m_axis_busy(m_busy),
        .M_AXIS_ACLK(m00_axis_aclk),
        .M_AXIS_ARESETN(m00_axis_aresetn),
        .M_AXIS_TVALID(m00_axis_tvalid),
        .M_AXIS_TDATA(m00_axis_tdata),
        .M_AXIS_TSTRB(m00_axis_tstrb),
        .M_AXIS_TLAST(m00_axis_tlast),
        .M_AXIS_TREADY(m00_axis_tready)
    );

    aes_128_ctr aes_design (
        .clk(s00_axis_aclk),
        .rst(!s00_axis_aresetn),
        .start(aes_start),
        .key(aes_key),
        .counter(aes_counter),
        .plaintext(aes_plaintext),
        .ciphertext(aes_ciphertext),
        .done(aes_done)
    );

endmodule
