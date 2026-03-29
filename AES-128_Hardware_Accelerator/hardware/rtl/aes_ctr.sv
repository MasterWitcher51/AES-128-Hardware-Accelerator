`timescale 1ns / 1ps

module aes_128_ctr(
    input  logic         clk,
    input  logic         rst,
    input  logic         start,
    input  logic [127:0] key,
    input  logic [127:0] counter,
    input  logic [127:0] plaintext,
    output logic [127:0] ciphertext,
    output logic         done
);

    typedef enum logic [2:0] {IDLE, INIT, ROUND, FINAL, DONE_STATE} state_t;
    state_t state, next_state;

    logic [127:0] state_reg, state_next;
    logic [3:0]   round;
    logic [127:0] round_key;
    logic [127:0] result_reg;

    key_expansion key_exp_inst (
        .clk(clk),
        .rst(rst),
        .startGen(start),
        .inKey(key),
        .round(round),
        .rKey(round_key),
        .idle()
    );

    logic [127:0] round_out, final_out;

    aes_encrypt_round u_round (
        .state_in(state_reg),
        .round_key(round_key),
        .state_out(round_out)
    );

    encrypt_final_round u_final_round (
        .state_in(state_reg),
        .round_key(round_key),
        .state_out(final_out)
    );

    // Sequential Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            state_reg  <= 128'd0;
            round      <= 4'd0;
            result_reg <= 128'd0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    if (start) begin
                        state_reg <= counter ^ key; // Initial AddRoundKey
                        round     <= 4'd1;           // Set up for Round 1 Key
                    end
                end
                INIT: begin
                    state_reg <= round_out;          // Compute Round 1
                    round     <= 4'd2;               // Prep Round 2 Key
                end
                ROUND: begin
                    state_reg <= round_out;          // Compute Rounds 2-9
                    round     <= round + 1'b1;
                end
                FINAL: begin
                    state_reg  <= final_out;         // Compute Round 10
                    result_reg <= final_out ^ plaintext; // Final CTR XOR
                end
            endcase
        end
    end

    // Combinational Logic for next state
    always_comb begin
        next_state = state;
        done       = 1'b0;
        ciphertext   = result_reg;

        case (state)
            IDLE:  if (start) next_state = INIT;
            INIT:  next_state = ROUND;
            ROUND: if (round == 4'd9) next_state = FINAL;
            FINAL: next_state = DONE_STATE;
            DONE_STATE: begin
                done = 1'b1;
                if (!start) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule