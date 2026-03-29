`timescale 1ns / 1ps

module key_expansion_tb();

  
    logic         clk=0, rst, startGen;
    logic [127:0] inKey, rKey;
    logic [3:0]   round;
    logic         idle;

    // NIST Expected Data
    logic [127:0] NIST_keys [11] = '{
        128'h2b7e151628aed2a6abf7158809cf4f3c, 128'ha0fafe1788542cb123a339392a6c7605,
        128'hf2c295f27a96b9435935807a7359f67f, 128'h3d80477d4716fe3e1e237e446d7a883b,
        128'hef44a541a8525b7fb671253bdb0bad00, 128'hd4d1c6f87c839d87caf2b8bc11f915bc,
        128'h6d88a37a110b3efddbf98641ca0093fd, 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f,
        128'head27321b58dbad2312bf5607f8d292f, 128'hac7766f319fadc2128d12941575c006e,
        128'hd014f9a8c9ee2589e13f0cc8b6630ca6
    };

    key_expansion uut (.*); // Uses implicit port mapping for simplicity

    // Clock Generation
    always #5 clk = ~clk;
    initial begin
        // Reset System
        rst = 1; startGen = 0; round = 0;
        inKey = NIST_keys[0]; 
        #20 rst = 0;
        
        $display("Starting Key Expansion Test...");

        // Start Generation
        @(posedge clk);
        startGen = 1;
        @(posedge clk);
        startGen = 0;

        // Wait for Idle (Expansion Complete)
        wait(idle);
        #10;

        // Verification Loop
        for (int r = 0; r <= 10; r++) begin
            round = r;
            #1;       
            if (rKey === NIST_keys[r])
                $display("Round %0d: PASS", r);
            else
                $display("Round %0d: FAIL (Got: %h, Exp: %h)", r, rKey, NIST_keys[r]);
        end

        $display("---------------------------------------");
        $display("Test Complete.");
        $finish;
    end

endmodule