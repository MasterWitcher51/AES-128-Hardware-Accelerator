module sub_bytes (
    input  logic [127:0] in,
    output logic [127:0] out
);

    Sbox s0  (.Sbox_in(in[127:120]), .Sbox_out(out[127:120]));
    Sbox s1  (.Sbox_in(in[119:112]), .Sbox_out(out[119:112]));
    Sbox s2  (.Sbox_in(in[111:104]), .Sbox_out(out[111:104]));
    Sbox s3  (.Sbox_in(in[103:96]),  .Sbox_out(out[103:96]));
 
    Sbox s4  (.Sbox_in(in[95:88]),   .Sbox_out(out[95:88]));
    Sbox s5  (.Sbox_in(in[87:80]),   .Sbox_out(out[87:80]));
    Sbox s6  (.Sbox_in(in[79:72]),   .Sbox_out(out[79:72]));
    Sbox s7  (.Sbox_in(in[71:64]),   .Sbox_out(out[71:64]));

    Sbox s8  (.Sbox_in(in[63:56]),   .Sbox_out(out[63:56]));
    Sbox s9  (.Sbox_in(in[55:48]),   .Sbox_out(out[55:48]));
    Sbox s10 (.Sbox_in(in[47:40]),   .Sbox_out(out[47:40]));
    Sbox s11 (.Sbox_in(in[39:32]),   .Sbox_out(out[39:32]));

    Sbox s12 (.Sbox_in(in[31:24]),   .Sbox_out(out[31:24]));
    Sbox s13 (.Sbox_in(in[23:16]),   .Sbox_out(out[23:16]));
    Sbox s14 (.Sbox_in(in[15:8]),    .Sbox_out(out[15:8]));
    Sbox s15 (.Sbox_in(in[7:0]),     .Sbox_out(out[7:0]));

endmodule
