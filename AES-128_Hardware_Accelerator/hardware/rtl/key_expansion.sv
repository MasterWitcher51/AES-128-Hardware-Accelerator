`timescale 1ns / 1ps

module key_expansion(
    input  logic         clk,
    input  logic         rst,
    input  logic         startGen,
    input  logic [127:0] inKey,
    input  logic [3:0]   round,   
    output logic [127:0] rKey,
    output logic         idle
);

    typedef enum logic {IDLE, EXPAND} state_t;
    state_t state;

    logic [127:0] w[0:10];
    logic [3:0]   cnt;
    logic         done;

    // Internal wires for the transformation of the last word of the previous key
    logic [31:0] prev_last_word;
    logic [31:0] rotOut, subWordOut, rconOut;

    assign prev_last_word = w[cnt-1][31:0];

    rot_word rotU (.in(prev_last_word), .out(rotOut));
    sub_word subU (.in(rotOut), .out(subWordOut));
    Rcon     rconU (.round(cnt), .rcon(rconOut));

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cnt   <= 0;
            done  <= 0;
            for (int i = 0; i <= 10; i++) w[i] <= 128'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (startGen) begin
                        w[0]  <= inKey;   // Load initial key
                        cnt   <= 4'd1;    // Start generating Round 1
                        done  <= 1'b0;
                        state <= EXPAND;
                    end
                end

                EXPAND: begin
                    // AES-128 Key Expansion XOR Logic
                    w[cnt][127:96] <= w[cnt-1][127:96] ^ subWordOut ^ rconOut;
                    w[cnt][95:64]  <= w[cnt-1][95:64]  ^ (w[cnt-1][127:96] ^ subWordOut ^ rconOut);
                    w[cnt][63:32]  <= w[cnt-1][63:32]  ^ (w[cnt-1][95:64]  ^ (w[cnt-1][127:96] ^ subWordOut ^ rconOut));
                    w[cnt][31:0]   <= w[cnt-1][31:0]   ^ (w[cnt-1][63:32]  ^ (w[cnt-1][95:64]  ^ (w[cnt-1][127:96] ^ subWordOut ^ rconOut)));

                    if (cnt == 4'd10) begin
                        state <= IDLE;
                        done  <= 1'b1;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end
            endcase
        end
    end

    assign idle = (state == IDLE) && done;
    assign rKey = w[round]; // Combinational reads

endmodule