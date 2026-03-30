# Test script for Hello World Application
set bit_file "C:/Users/adamo/Downloads/TutorialWorkspace/TutorialTest/export/TutorialTest/hw/sdt/design_1_wrapper.bit"
set elf_file "C:/Users/adamo/Downloads/TutorialWorkspace/hello_world/build/hello_world.elf"
set psinit   "C:/Users/adamo/Downloads/TutorialWorkspace/TutorialTest/hw/sdt/ps7_init.tcl"

# Connect to board
connect


targets -set -filter {name =~ "APU*"}
rst -system
source $psinit
ps7_init
ps7_post_config


# Program Bitstream
targets -set -filter {name =~ "xc7z010"}
fpga -file $bit_file
after 1000



targets -set -filter {name =~ "*Hart*"}
rst -processor
after 200
dow $elf_file

con
