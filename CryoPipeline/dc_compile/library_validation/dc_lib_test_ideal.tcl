define_design_lib WORK -path ./WORK

set TOP_MODULE BoomCore
set src_path "./src_vlg"
set PDK_path "./freepdk-45nm/stdview"
set SYN_path "/home/synopsys/dc_compiler_2019/syn/P-2019.03/libraries/syn"

set search_path "$src_path \ $PDK_path \ $SYN_path"

set target_library "$PDK_path/NangateOpenCellLibrary.db"
set synthetic_library "$SYN_path/dw_foundation.sldb"
set link_library "* $target_library $synthetic_library"
set mw_reference_library "./milky-45nm-ideal"
set mw_design_library "./mw_design_lib_ideal"
set technology_file "$PDK_path/rtk-tech-ideal.tf"

open_mw_lib $mw_design_library
check_library
exit
