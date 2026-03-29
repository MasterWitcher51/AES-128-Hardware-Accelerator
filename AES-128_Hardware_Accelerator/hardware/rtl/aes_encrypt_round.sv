module aes_encrypt_round (
    input  logic [127:0] state_in,
    input  logic [127:0] round_key,
    output logic [127:0] state_out
);

    logic [127:0] sb_out;
    logic [127:0] sr_out;
    logic [127:0] mc_out;

    sub_bytes   u_sub_bytes   (.in(state_in),  .out(sb_out));
    shift_rows  u_shift_rows  (.in(sb_out),    .out(sr_out));
    mix_columns u_mix_columns(.in(sr_out),    .out(mc_out));
    add_round_key u_add_round_key (.state(mc_out),.key(round_key),.out(state_out));

endmodule
