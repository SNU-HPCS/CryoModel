read_lef -lib_name milky-45nm-77k -tech_lef_files ./freepdk-45nm/stdview/rtk-tech-77k.lef -cell_lef_files "./freepdk-45nm/stdview/stdcells.lef"
cmDumpTech
setFormField "Dump Technology File" "Library Name" "milky-45nm-77k"
setFormField "Dump Technology File" "Technology File Name" "milky-45nm-77k.tf"
formOK "Dump Technology File"
exit
