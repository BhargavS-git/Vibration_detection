set_attribute init_lib_search_path /home/install/FOUNDRY/digital/90nm/dig/lib

set_attribute library slow.lib

read_hdl {./vibration_anomaly_detector.v}

elaborate

read_sdc ./vibration_constraints.sdc

# Aggressive low-power synthesis settings for an always-on edge tile
set_attribute syn_generic_effort medium
set_attribute syn_map_effort    medium
set_attribute syn_opt_effort    medium

syn_generic
syn_map
syn_opt

write_hdl > vibration_netlist.v
write_sdc  > vibration_tool.sdc

gui_show

report timing > vibration_timing.rpt
report power > vibration_power.rpt
report area > vibration_cell.rpt
report gates > vibration_gates.rpt
