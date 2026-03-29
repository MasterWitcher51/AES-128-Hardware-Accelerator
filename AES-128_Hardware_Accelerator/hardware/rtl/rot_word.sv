module rot_word (
    input  logic [31:0] in,
    output logic [31:0] out
);
    assign out = {in[23:0], in[31:24]};
endmodule
