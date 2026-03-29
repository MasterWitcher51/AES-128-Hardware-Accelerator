`timescale 1ns / 1ps
module AES_AXI_Core_slave_stream_v1_0_S00_AXIS #
(
    parameter integer C_S_AXIS_TDATA_WIDTH = 32
)
(
    output reg  [127:0] o_aes_plaintext,
    output reg          o_aes_start,
    input  wire         i_aes_ready,
    input  wire         S_AXIS_ACLK,
    input  wire         S_AXIS_ARESETN,
    output wire         S_AXIS_TREADY,
    input  wire [C_S_AXIS_TDATA_WIDTH-1:0] S_AXIS_TDATA,
    input  wire [(C_S_AXIS_TDATA_WIDTH/8)-1:0] S_AXIS_TSTRB,
    input  wire         S_AXIS_TLAST,
    input  wire         S_AXIS_TVALID
);
    reg [1:0]   word_cnt;
    reg [127:0] data_buffer;
    reg         trigger_pending;

    assign S_AXIS_TREADY = !trigger_pending && !o_aes_start;

    always @(posedge S_AXIS_ACLK) begin
        if (S_AXIS_ARESETN == 1'b0) begin
            word_cnt        <= 2'b00;
            data_buffer     <= 128'h0;
            o_aes_plaintext <= 128'h0;
            o_aes_start     <= 1'b0;
            trigger_pending <= 1'b0;
        end else begin
            o_aes_start <= 1'b0;

            if (S_AXIS_TVALID && S_AXIS_TREADY) begin
                case (word_cnt)
                    2'b00: data_buffer[127:96] <= S_AXIS_TDATA;
                    2'b01: data_buffer[95:64]  <= S_AXIS_TDATA;
                    2'b10: data_buffer[63:32]  <= S_AXIS_TDATA;
                    2'b11: begin
                        o_aes_plaintext <= {data_buffer[127:32], S_AXIS_TDATA};
                        trigger_pending <= 1'b1;
                        word_cnt        <= 2'b00;
                    end
                endcase
                if (word_cnt != 2'b11)
                    word_cnt <= word_cnt + 1'b1;
            end

            if (trigger_pending) begin
                o_aes_start     <= 1'b1;
                trigger_pending <= 1'b0;
            end
        end
    end

endmodule
