module mix_columns (
    input  logic [127:0] in,
    output logic [127:0] out
);

    function automatic [7:0] xtime(input [7:0] a);
        xtime = a[7] ? ((a << 1) ^ 8'h1B) : (a << 1);
    endfunction

    function automatic [31:0] mix_single_column(input [31:0] col);
        logic [7:0] a0, a1, a2, a3;
        logic [7:0] t, u;
        begin
            {a0, a1, a2, a3} = col;

            t = a0 ^ a1 ^ a2 ^ a3;
            u = a0;

            mix_single_column = {
                a0 ^ t ^ xtime(a0 ^ a1),
                a1 ^ t ^ xtime(a1 ^ a2),
                a2 ^ t ^ xtime(a2 ^ a3),
                a3 ^ t ^ xtime(a3 ^ u)
            };
        end
    endfunction

    assign out[127:96] = mix_single_column(in[127:96]); 
    assign out[95:64]  = mix_single_column(in[95:64]);  
    assign out[63:32]  = mix_single_column(in[63:32]);  
    assign out[31:0]   = mix_single_column(in[31:0]);  

endmodule
