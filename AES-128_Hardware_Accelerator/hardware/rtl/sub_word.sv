module sub_word (
    input  logic [31:0] in,
    output logic [31:0] out
);
    Sbox s0 (.Sbox_in(in[31:24]), .Sbox_out(out[31:24]));
    Sbox s1 (.Sbox_in(in[23:16]), .Sbox_out(out[23:16]));
    Sbox s2 (.Sbox_in(in[15:8]),  .Sbox_out(out[15:8]));
    Sbox s3 (.Sbox_in(in[7:0]),   .Sbox_out(out[7:0]));
endmodule
