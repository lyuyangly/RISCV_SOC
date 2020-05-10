# -----------------------------------------------------------------------------
# Vivado Non-Project Flow
# -----------------------------------------------------------------------------
set DESIGN      [lindex $argv 0]
set PRJ_PATH    [lindex $argv 1]

# -----------------------------------------------------------------------------
config_webtalk -user off

# -----------------------------------------------------------------------------
create_project -in_memory -part xc7z020clg400-2

# -----------------------------------------------------------------------------
proc read_filelist {filelist} {
    global hdl_list
    global incdir_list
    set fp [open $filelist r]
    while {[gets $fp fname] != -1} {
        if {[regexp {^//} $fname]} {
            continue
        } elseif {[regexp {^\S+\.v} $fname]} {
            regsub {\$PRJ_PATH} $fname $::PRJ_PATH fname_sub
            lappend hdl_list $fname_sub
        } elseif {[regexp {^\S+\.sv} $fname]} {
            regsub {\$PRJ_PATH} $fname $::PRJ_PATH fname_sub
            lappend hdl_list $fname_sub
        } elseif {[regexp {^-v} $fname]} {
            regsub {-v\s+\$PRJ_PATH} $fname $::PRJ_PATH fname_sub
            lappend hdl_list $fname_sub
        } elseif {[regexp {^\+incdir\+} $fname]} {
            regsub {^\+incdir\+} $fname "" fname_sub
            lappend incdir_list $fname_sub
        }
    }
    close $fp
}

# -----------------------------------------------------------------------------
set hdl_list ""
set incdir_list ""
read_filelist "$PRJ_PATH/rtl/filelist/filelist.lst"

set_property verilog_define "SYNTHESIS" [current_fileset]
set_property include_dirs $incdir_list [current_fileset]
set_property top ${DESIGN} [current_fileset]

read_verilog $hdl_list
#read_ip "../scr/ila_debug.xci"
read_xdc "../scr/${DESIGN}.xdc"

# -----------------------------------------------------------------------------
synth_design -top ${DESIGN} -part xc7z020clg400-2
write_checkpoint -force ../rpt/${DESIGN}_synth.dcp
report_utilization -file ../rpt/${DESIGN}_synth_utilization.rpt
report_timing_summary -file ../rpt/${DESIGN}_synth_timing_summary.rpt

# -----------------------------------------------------------------------------
if {[llength [get_debug_cores -quiet]] > 0} {
    implement_debug_core
}

write_debug_probes ../rpt/${DESIGN}.ltx

# -----------------------------------------------------------------------------
opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force ../rpt/${DESIGN}_placed.dcp
report_utilization -file ../rpt/${DESIGN}_placed_utilization.rpt
report_timing_summary -file ../rpt/${DESIGN}_placed_timing_summary.rpt

# -----------------------------------------------------------------------------
route_design -directive Explore -tns_cleanup
phys_opt_design -directive Explore
write_checkpoint -force ../rpt/${DESIGN}_routed.dcp
report_route_status -file ../rpt/${DESIGN}_routed_status.rpt
report_timing_summary -file ../rpt/${DESIGN}_routed_timing_summary.rpt

# -----------------------------------------------------------------------------
write_bitstream -force ../rpt/${DESIGN}.bit
write_cfgmem -format bin -interface SPIx1 -size 256 -loadbit "up 0 ../rpt/${DESIGN}.bit" ../rpt/${DESIGN}.bin

