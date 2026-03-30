`timescale 1 ns / 1 ps

module AES_AXI_Core_master_stream_v1_0_M00_AXIS #
(
    parameter integer C_M_AXIS_TDATA_WIDTH = 32
)
(
    input wire [127:0] i_aes_ciphertext,
    input wire         i_aes_done,
    output wire        o_m_axis_busy, // Feeds back to Slave TREADY

    input wire         M_AXIS_ACLK,
    input wire         M_AXIS_ARESETN,
    output wire        M_AXIS_TVALID,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
    output wire [3 : 0] M_AXIS_TSTRB,
    output wire        M_AXIS_TLAST,
    input wire         M_AXIS_TREADY
);

    localparam IDLE = 1'b0, SEND = 1'b1;
    reg         state;
    reg [1:0]   word_cnt;
    reg [127:0] data_reg;

    assign M_AXIS_TVALID = (state == SEND);
    assign M_AXIS_TSTRB  = 4'b1111;
    assign M_AXIS_TLAST  = (state == SEND) && (word_cnt == 2'b11);
    
    // System is busy if sending or if data just arrived
    assign o_m_axis_busy = (state == SEND);
    // Ciphertext is sent in 4 words
    assign M_AXIS_TDATA = (word_cnt == 2'b00) ? data_reg[127:96] :
                          (word_cnt == 2'b01) ? data_reg[95:64]  :
                          (word_cnt == 2'b10) ? data_reg[63:32]  :
                                                data_reg[31:0];

    always @(posedge M_AXIS_ACLK) begin
        if (!M_AXIS_ARESETN) begin
            state      <= IDLE;
            word_cnt   <= 2'b00;
            data_reg <= 128'h0;
        end 
        else begin
            case (state)
                IDLE: begin
                    if (i_aes_done) begin
                    // Retrieves full 128-bit ciphertext
                        data_reg <= i_aes_ciphertext;
                        state      <= SEND;
                        word_cnt   <= 2'b00;
                    end
                end
                SEND: begin
                    if (M_AXIS_TVALID && M_AXIS_TREADY) begin
                        if (word_cnt == 2'b11) begin
                            state    <= IDLE;
                            word_cnt <= 2'b00;
                        end 
                        else begin
                            word_cnt <= word_cnt + 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
