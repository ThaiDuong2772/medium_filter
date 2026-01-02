transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter {C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter/median_9.v}

vlog -vlog01compat -work work +incdir+C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter {C:/Workspace/uit_k18/VHDL/Thuc_Hanh/Lab2/medium_filter/tb_median_filter_opt.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneii_ver -L rtl_work -L work -voptargs="+acc"  tb_median_filter_opt

add wave *
view structure
view signals
run -all
