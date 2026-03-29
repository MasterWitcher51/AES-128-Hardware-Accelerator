`timescale 1ns / 1ps

module aes_axi_system_tb();

    logic clk = 0;
    logic rst_n = 0;
    
    // AXI-Lite
    logic [4:0]  axi_addr;
    logic        axi_awvalid, axi_wvalid, axi_bready;
    logic [31:0] axi_wdata;
    wire         axi_awready, axi_wready, axi_bvalid;

    // AXI-Stream Slave (
    logic [31:0] s_tdata;
    logic        s_tvalid, s_tlast;
    wire         s_tready;

    // AXI-Stream Master 
    wire [31:0]  m_tdata;
    wire         m_tvalid, m_tlast;
    logic        m_tready;

    // Test Vectors
    logic [31:0] plaintext1 [0:3] = '{32'h6bc1bee2, 32'h2e409f96, 32'he93d7e11, 32'h7393172a};
    logic [31:0] expected1 [0:3]  = '{32'h874d6191, 32'hb620e326, 32'h1bef6864, 32'h990db6ce};
    
    logic [31:0] plaintext2 [0:3] = '{32'hae2d8a57, 32'h1e03ac9c, 32'h9eb76fac, 32'h45af8e51};
    logic [31:0] expected2 [0:3]  = '{32'h9806f66b, 32'h7970fdff, 32'h8617187b, 32'hb9fffdff};

    // Counter values
    logic [31:0] counter_words [4][4] = '{
        '{32'hf0f1f2f3, 32'hf4f5f6f7, 32'hf8f9fafb, 32'hfcfdfeff},
        '{32'hf0f1f2f3, 32'hf4f5f6f7, 32'hf8f9fafb, 32'hfcfdff00},
        '{32'hf0f1f2f3, 32'hf4f5f6f7, 32'hf8f9fafb, 32'hfcfdff01},
        '{32'hf0f1f2f3, 32'hf4f5f6f7, 32'hf8f9fafb, 32'hfcfdff02}
    };

    // Buffers for verification
    logic [31:0] captured_ciphertext [0:3];
    logic [31:0] actual [0:3];

 
    always #5 clk = ~clk;

  
    AES_AXI_Core_0 dut (
        .s00_axi_aclk(clk),
        .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr(axi_addr),
        .s00_axi_awprot(3'b000),
        .s00_axi_awvalid(axi_awvalid),
        .s00_axi_awready(axi_awready),
        .s00_axi_wdata(axi_wdata),
        .s00_axi_wstrb(4'hf),
        .s00_axi_wvalid(axi_wvalid),
        .s00_axi_wready(axi_wready),
        .s00_axi_bvalid(axi_bvalid),
        .s00_axi_bready(axi_bready),
        
        .s00_axis_aclk(clk),
        .s00_axis_aresetn(rst_n),
        .s00_axis_tdata(s_tdata),
        .s00_axis_tvalid(s_tvalid),
        .s00_axis_tready(s_tready),
        .s00_axis_tlast(s_tlast),

        .m00_axis_aclk(clk),
        .m00_axis_aresetn(rst_n),
        .m00_axis_tdata(m_tdata),
        .m00_axis_tvalid(m_tvalid),
        .m00_axis_tready(m_tready),
        .m00_axis_tlast(m_tlast)
    );

    // --- Helper Tasks ---
    task axi_lite_write(input [4:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            axi_addr <= addr; axi_awvalid <= 1;
            axi_wdata <= data; axi_wvalid <= 1;
            axi_bready <= 1;
            fork wait(axi_awready); wait(axi_wready); join
            @(posedge clk);
            axi_awvalid <= 0; axi_wvalid <= 0;
            wait(axi_bvalid); @(posedge clk); axi_bready <= 0;
        end
    endtask

    task configure_counter(input int block_num);
        begin
            $display("--- Configuring Counter for Block #%0d ---", block_num);
            axi_lite_write(5'h10, counter_words[block_num-1][0]);
            axi_lite_write(5'h14, counter_words[block_num-1][1]);
            axi_lite_write(5'h18, counter_words[block_num-1][2]);
            axi_lite_write(5'h1C, counter_words[block_num-1][3]);
        end
    endtask

    task send_stream(input logic [31:0] words [0:3]);
        begin
            @(posedge clk);
            s_tvalid = 1;
            s_tdata = words[0]; wait(s_tready); @(posedge clk);
            s_tdata = words[1]; wait(s_tready); @(posedge clk);
            s_tdata = words[2]; wait(s_tready); @(posedge clk);
            s_tdata = words[3]; s_tlast = 1; wait(s_tready); @(posedge clk);
            s_tvalid = 0; s_tlast = 0;
        end
    endtask

    task receive_and_verify(input logic [31:0] expected_data [0:3], input string mode);
        begin
            for (int i=0; i<4; i++) begin
                wait(m_tvalid);
                actual[i] = m_tdata;
                if (mode == "ENCRYPT") captured_ciphertext[i] = m_tdata;
                m_tready = 1;
                
                if (actual[i] == expected_data[i])
                    $display("  %s Word %0d: %h (MATCH!)", mode, i, actual[i]);
                else
                    $display("  %s Word %0d: %h (ERROR! Expected %h)", mode, i, actual[i], expected_data[i]);
                
                @(posedge clk);
                #1 m_tready = 0;
            end
        end
    endtask

    initial begin
        // Initialize
        rst_n = 0; m_tready = 0; s_tvalid = 0; s_tlast = 0;
        #100 rst_n = 1; #100;

        $display("==================================================");
        $display("STARTING AES-128 CTR ROUND-TRIP TEST");
        $display("==================================================");
        
        // Step 1: Set Secret Key
        $display("--- Step 1: Configuring Secret Key ---");
        axi_lite_write(5'h00, 32'h2b7e1516); 
        axi_lite_write(5'h04, 32'h28aed2a6);
        axi_lite_write(5'h08, 32'habf71588); 
        axi_lite_write(5'h0C, 32'h09cf4f3c);
        
        $display("\n Encryption (Plaintext -> Ciphertext)");
        configure_counter(1);
        send_stream(plaintext1);
        receive_and_verify(expected1, "ENCRYPT");

        #200;

        // Step 3: Decryption Pass (Hardware same as encryption)
        $display("Decryption ");
        configure_counter(1); // Use same counter
        send_stream(captured_ciphertext);
        receive_and_verify(plaintext1, "DECRYPT");

        #200;
        $display("SIMULATION FINISHED: CTR ROUND-TRIP VERIFIED");
        $finish;
    end

endmodule