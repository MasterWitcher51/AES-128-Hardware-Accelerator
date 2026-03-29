module aes_decrypt_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    output logic [127:0] state_out
);

    logic [127:0] isr_out;
    logic [127:0] isb_out;
    logic [127:0] ark_out;

    InvShiftRows  u1 (.in(state_in), .out(isr_out));
    InvSubBytes   u2 (.in(isr_out),  .out(isb_out));
    add_round_key u3 (.state(isb_out), .key(round_key), .out(ark_out));
    InvMixColumns u4 (.in(ark_out), .out(state_out));

endmodule
