# Software AES Image Encryption TCL Script 

set image_in  "C:/Users/adamo/Downloads/AES_Vitis_FYP/image2.bin"
set image_enc "C:/Users/adamo/Downloads/AES_Vitis_FYP/sw_enc2.bin"
set image_dec "C:/Users/adamo/Downloads/AES_Vitis_FYP/sw_dec2.bin"
set elf_file  "C:/Users/adamo/Downloads/AES_Vitis_FYP/AES_128_C_Version/build/AES_128_C_Version.elf"
set bit_file  "C:/Users/adamo/Downloads/AES_Vitis_FYP/AES_128_C_Version/_ide/bitstream/design_3_wrapper.bit"
set psinit    "C:/Users/adamo/Downloads/AES_Vitis_FYP/Software_Platform/export/Software_Platform/hw/sdt/ps7_init.tcl"

set IMG_ADDR      0x10100000
set ENC_ADDR      0x12100000   ;# 32MB after IMG
set DEC_ADDR      0x14100000   ;# 32MB after ENC
set STATUS_ADDR   0x10008000
set IMG_SIZE_ADDR 0x10008004   ;# C reads image size from here


# Auto-detect image size from file
set fp [open $image_in rb]
fconfigure $fp -translation binary
seek $fp 0 end
set IMG_SIZE [tell $fp]
close $fp

# Round down to multiple of 16 (AES block size)
set IMG_SIZE [expr {($IMG_SIZE / 16) * 16}]
set NUM_WORDS [expr {$IMG_SIZE / 4}]

puts "Image file:  $image_in"
puts "Image size:  $IMG_SIZE bytes ([expr {$IMG_SIZE / 1024}] KB)"
puts "Blocks:      [expr {$IMG_SIZE / 16}]"

# Sanity check — warn if over 50MB
if {$IMG_SIZE > 52428800} {
    puts "WARNING: Image is over 50MB — may exceed DDR buffer layout"
    puts "         Check buffer addresses in C driver"
}


# Step 1: Connect and init
puts "\n--- Connecting ---"
connect

targets -set -filter {name =~ "APU*"}
rst -system
source $psinit
ps7_init
ps7_post_config


# Step 2: Program bitstream
puts "\n--- Programming Bitstream ---"
targets -set -filter {name =~ "xc7z010"}
fpga -file $bit_file
after 2000


# Step 3: Write image size to DDR so C driver knows it
puts "\n--- Writing image size to DDR ---"
targets -set -filter {name =~ "ARM*#0"}
mwr -size w $IMG_SIZE_ADDR $IMG_SIZE
set readback [lindex [mrd -value -size w $IMG_SIZE_ADDR] 0]
puts "IMG_SIZE written:  $IMG_SIZE"
puts "IMG_SIZE readback: $readback"


# Step 4: Load image into DDR
puts "\n--- Loading image into DDR at [format 0x%08X $IMG_ADDR] ---"
dow -data $image_in $IMG_ADDR


# Step 5: Load and run ELF
puts "\n--- Starting MicroBlaze-V ---"

# --- Start TCL timer ---
set start_time [clock milliseconds]

targets -set -filter {name =~ "Hart #0"}
rst -processor
after 200
dow $elf_file
con


# Step 6: Poll Status
puts "\n--- Waiting for completion ---"
targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}

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

}
# --- Stop TCL timer and calculate ---
set end_time [clock milliseconds]
set total_ms [expr {$end_time - $start_time}]
set total_sec [expr {$total_ms / 1000.0}]


# Step 7: Save results
# Uses chunked mrd — chunk_size 64 words is reliable
#
puts "\n--- Saving Results to PC ---"
targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}

# mrd -bin -file streams memory directly to a file on your hard drive
puts "Saving Encrypted Image..."
mrd -bin -file $image_enc $ENC_ADDR $NUM_WORDS

puts "Saving Decrypted Image..."
mrd -bin -file $image_dec $DEC_ADDR $NUM_WORDS
puts "  TCL Execution Time: $total_sec seconds"
