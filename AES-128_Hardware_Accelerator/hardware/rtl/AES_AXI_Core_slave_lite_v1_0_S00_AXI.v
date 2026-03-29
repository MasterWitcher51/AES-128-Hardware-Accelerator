`timescale 1 ns / 1 ps

module AES_AXI_Core_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5 
)
(
    // User Ports: Outputs to AES Core
    output wire [127:0] o_aes_key,
    output wire [127:0] o_aes_counter,

    // AXI-Lite Interface
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    // Internal AXI Signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
    reg  	axi_awready;
    reg  	axi_wready;
    reg [1 : 0] 	axi_bresp;
    reg  	axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
    reg  	axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
    reg [1 : 0] 	axi_rresp;
    reg  	axi_rvalid;

    // Address parameters
    localparam integer ADDR_LSB = 2; 
    localparam integer OPT_MEM_ADDR_BITS = 2; // Supports 8 registers

    // Slave Registers
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0; // Key [31:0]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1; // Key [63:32]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2; // Key [95:64]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3; // Key [127:96]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4; // Counter [31:0]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5; // Counter [63:32]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6; // Counter [95:64]
    reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7; // Counter [127:96]

    // Interface Assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // Combine 32-bit registers into 128-bit wires
    assign o_aes_key     = {slv_reg0, slv_reg1, slv_reg2, slv_reg3};
    assign o_aes_counter = {slv_reg4, slv_reg5, slv_reg6, slv_reg7};

    // Write Address Ready (AWREADY)
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_awready <= 1'b0;
        else if (~axi_awready && S_AXI_AWVALID)
            axi_awready <= 1'b1;
        else
            axi_awready <= 1'b0;
    end

    // Write Address Capture
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID)
            axi_awaddr <= S_AXI_AWADDR;
    end

    // Write Data Ready (WREADY)
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 )
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    // Register Write Enable
    wire slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // Register Write Logic
    integer byte_index;
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            slv_reg0 <= 0; slv_reg1 <= 0; slv_reg2 <= 0; slv_reg3 <= 0;
            slv_reg4 <= 0; slv_reg5 <= 0; slv_reg6 <= 0; slv_reg7 <= 0;
        end else if (slv_reg_wren) begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                3'h0: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg0[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h1: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg1[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h2: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg2[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h3: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg3[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h4: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg4[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h5: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg5[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h6: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg6[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
                3'h7: for (byte_index=0; byte_index<4; byte_index=byte_index+1) if (S_AXI_WSTRB[byte_index]) slv_reg7[(byte_index*8)+:8] <= S_AXI_WDATA[(byte_index*8)+:8];
            endcase
        end
    end

    // Write Response (BVALID)
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid) begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b0; 
        end else if (S_AXI_BREADY && axi_bvalid)
            axi_bvalid <= 1'b0;
    end

    // Read Address Ready (ARREADY)
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end else if (~axi_arready && S_AXI_ARVALID) begin
            axi_arready <= 1'b1;
            axi_araddr  <= S_AXI_ARADDR;
        end else
            axi_arready <= 1'b0;
    end

    // Read Data/Valid (RVALID)
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b0;
        end else if (axi_rvalid && S_AXI_RREADY)
            axi_rvalid <= 1'b0;
    end

    // Register Read Mux
    wire [2:0] read_addr = axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
    always @(*) begin
        case ( read_addr )
            3'h0 : axi_rdata = slv_reg0;
            3'h1 : axi_rdata = slv_reg1;
            3'h2 : axi_rdata = slv_reg2;
            3'h3 : axi_rdata = slv_reg3;
            3'h4 : axi_rdata = slv_reg4;
            3'h5 : axi_rdata = slv_reg5;
            3'h6 : axi_rdata = slv_reg6;
            3'h7 : axi_rdata = slv_reg7;
            default : axi_rdata = 32'h0;
        endcase
    end

endmodule
