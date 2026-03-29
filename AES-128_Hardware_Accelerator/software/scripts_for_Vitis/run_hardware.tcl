
# AES Image Hardware Test TCL Script

# File Paths form input image and for outputs
set image_in  "C:/Users/adamo/Downloads/AES_Vitis_FYP/image2.bin"
set image_enc "C:/Users/adamo/Downloads/AES_Vitis_FYP/hw_enc2.bin"
set image_dec "C:/Users/adamo/Downloads/AES_Vitis_FYP/hw_dec2.bin"
set elf_file  "C:/Users/adamo/Downloads/AES_Vitis_FYP/hello_world/build/hello_world.elf"
set bit_file  "C:/Users/adamo/Downloads/AES_Vitis_FYP/hello_world/_ide/bitstream/design_3_wrapper.bit"
set psinit    "C:/Users/adamo/Downloads/AES_Vitis_FYP/Hardware_Platform/hw/sdt/ps7_init.tcl"

# Memory Map 
set IMG_ADDR      0x10100000
set ENC_ADDR      0x12100000   ;# 32MB after IMG
set DEC_ADDR      0x14100000   ;# 32MB after ENC
set STATUS_ADDR   0x10008000
set IMG_SIZE_ADDR 0x10008004


# Auto-detect image size from file
# Rounds down to nearest multiple of 16 for AES alignment

set fp [open $image_in rb]
fconfigure $fp -translation binary
seek $fp 0 end
set raw_size [tell $fp]
close $fp

# Round down to multiple of 16
set IMG_SIZE [expr {($raw_size / 16) * 16}]
set NUM_WORDS [expr {$IMG_SIZE / 4}]


# Step 1: Connect and init

puts "\n--- Connecting ---"
connect

targets -set -filter {name =~ "APU*"}
rst -system
source $psinit
ps7_init
ps7_post_config


# Step 2: Program Bitstream

puts "\n--- Programming Bitstream ---"
targets -set -filter {name =~ "xc7z010"}
fpga -file $bit_file
after 1000

# Step 3: Load image into DDR
puts "\n--- Streaming image.bin to DDR ---"
targets -set -filter {name =~ "ARM*#0"}
dow -data $image_in $IMG_ADDR


# Step 4: Write image size to DDR
puts "\n--- Writing image size to DDR ---"
mwr -size w $IMG_SIZE_ADDR $IMG_SIZE

# Verify the write
set readback [lindex [mrd -value -size w $IMG_SIZE_ADDR] 0]
puts "IMG_SIZE written:   $IMG_SIZE"
puts "IMG_SIZE readback:  $readback"

if {$readback != $IMG_SIZE} {
    puts "ERROR: Size write failed — aborting"
    exit 1
}


# Step 5: Load and run ELF on MicroBlaze-V

puts "\n--- Starting MicroBlaze-V ---"
set start_time [clock milliseconds]
targets -set -filter {name =~ "*Hart*"}
rst -processor
dow $elf_file
con


# Step 6: Poll Status
targets -set -filter {name =~ "ARM*#0"}
puts "Hardware processing..."
set last_status 0

while {1} {
    set status [lindex [mrd -value -size w $STATUS_ADDR] 0]

    if {$status != $last_status} {
        set last_status $status

        if {$status == 0x00000001} {
            puts "  Running..."
        } elseif {$status == 0x00000002} {
            puts "  Encryption complete"
        } elseif {$status == 0x00000003} {
            puts "  Decryption complete"
        } elseif {$status == 0x00000004} {
            puts "  PASS "
            break
        }
    }
    after 500
}
set end_time [clock milliseconds]
set total_ms [expr {$end_time - $start_time}]
set total_sec [expr {$total_ms / 1000.0}]


# Step 7: Save results
# NUM_WORDS calculated from detected file size
puts "\n--- Saving results ---"
targets -set -filter {name =~ "ARM*#0"}

puts "Saving hw_enc.bin ($IMG_SIZE bytes)..."
mrd -bin -file $image_enc $ENC_ADDR $NUM_WORDS

puts "Saving hw_dec.bin ($IMG_SIZE bytes)..."
mrd -bin -file $image_dec $DEC_ADDR $NUM_WORDS


puts "  DONE"
puts "  TCL Execution Time: $total_sec seconds"
