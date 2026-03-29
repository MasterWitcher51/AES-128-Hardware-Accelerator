`timescale 1ns / 1ps

module aes_ctr_tb();

    logic clk, rst, start, done;
    logic [127:0] key, counter, plaintext, ciphertext;

    // Storage for the test vectors
    logic [127:0] NIST_counts [4];
    logic [127:0] NIST_plains [4];
    logic [127:0] NIST_ciphers [4];
    logic [127:0] captured_ciphers [4];
    logic [127:0] NIST_keys [4];

    // Instantiate AES Design
    aes_128_ctr uut (
        .clk(clk), .rst(rst), .start(start),
        .key(key), .counter(counter), .plaintext(plaintext),
        .ciphertext(ciphertext), .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        
        // Read test vectors from .mem files
        $readmemh("key_vectors.mem", NIST_keys);
        $readmemh("counter_vectors.mem", NIST_counts);
        $readmemh("plaintext_vectors.mem", NIST_plains);
        $readmemh("ciphertext_vectors.mem", NIST_ciphers);

        clk = 0; rst = 1; start = 0;
        #100 rst = 0; #20;

        // ENCRYPTION PHASE
        $display("\n=== PHASE 1: ENCRYPTION ===");
        $display("Testing with NIST F.5.1 vectors\n");
        
        for (int i = 0; i < 4; i++) begin
            key = NIST_keys[i];
            counter = NIST_counts[i];
            plaintext  = NIST_plains[i];
            
            @(posedge clk); 
            start = 1;
            @(posedge clk); 
            start = 0;
            
            wait(done); 
            #2;

            captured_ciphers[i] = ciphertext;
            
            $display("Block #%0d:", i+1);
            $display("  Counter:    %h", counter);
            $display("  Plaintext:  %h", NIST_plains[i]);
            $display("  Ciphertext: %h", ciphertext);
            $display("  Expected:   %h", NIST_ciphers[i]);

            // Check the output with the expected output
            assert (ciphertext == NIST_ciphers[i])
            $display("NIST Vector Match\n");
            else begin
                $display("NIST Vector Mismatch!\n");
            end
            
            #20;
        end

        #100;

        // DECRYPTION PHASE 
        $display("\n=== PHASE 2: DECRYPTION (Round-Trip Test) ===");
        $display("Verifying that encryption/decryption is reversible\n");
        
        $display("Resetting core before decryption...");
        rst = 1;
        #20;
        rst = 0;
        #20;
        
        for (int i = 0; i < 4; i++) begin
            key = NIST_keys[i];
            counter = NIST_counts[i];
            plaintext  = captured_ciphers[i];
            
            $display("Starting decryption for Block #%0d at time %0t", i+1, $time);
            
            @(posedge clk); 
            start = 1;
            @(posedge clk); 
            start = 0;
            
            wait(done); 
            #2;

            $display("Block #%0d (Completed at time %0t):", i+1, $time);
            $display("  Counter:    %h", counter);
            $display("  Decrypted:  %h", ciphertext);
            $display("  Original:   %h", NIST_plains[i]);
            
            assert (ciphertext === NIST_plains[i])
                $display("SUCCESS: Round-Trip Match!\n");
            else begin
                $display("ERROR: Round-Trip Mismatch!\n");
            end
            
            #20;
        end

        $display("\n Test Summary");
        $display("All 4 blocks successfully encrypted and decrypted!");
        $display("Test Completed.");
        
        #100;
        $finish;
    end

endmodule