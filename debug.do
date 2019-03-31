# 项目中的work库和磁盘上的work库映射
vmap work work
# 增量式编译, 仅编译最新改动过的文件
vlog -incr src/alu.v src/global.v src/reg_file.v src/cpu.v src/mem.v src/pc.v src/sign_extend.v
vlog -incr src/decoder.v src/cpu_control.v
vlog -incr test/test_cpu.v
# 仿真启动
vsim -novopt work.test_cpu
# 监视端口设置
add wave -noupdate  /test_cpu/clk
add wave -noupdate /test_cpu/cpu/cpu_clk
add wave -noupdate /test_cpu/cpu/cpu_en
add wave -noupdate /test_cpu/cpu/cpu_rd
add wave -noupdate /test_cpu/cpu/cpu_wr
add wave -noupdate /test_cpu/cpu/pc_out
add wave -noupdate -color {Spring green}  /test_cpu/cpu/inst
# add wave -noupdate -color yellow /test_cpu/cpu/addr_src
# add wave -noupdate -color yellow /test_cpu/cpu/reg_dst
# add wave -noupdate -color yellow /test_cpu/cpu/alu_src
# add wave -noupdate -color yellow /test_cpu/cpu/mem_to_reg
# add wave -noupdate -color yellow /test_cpu/cpu/sign_expand
# add wave -noupdate -color yellow /test_cpu/cpu/branch
# add wave -noupdate -color yellow /test_cpu/cpu/jump
add wave -noupdate -color yellow /test_cpu/cpu/alu/alu_overflow
add wave -noupdate -color yellow /test_cpu/cpu/alu/alu_zero
add wave -noupdate -color magenta /test_cpu/cpu/alu/alu_in1
add wave -noupdate -color magenta /test_cpu/cpu/alu/alu_in2
add wave -noupdate -color magenta /test_cpu/cpu/alu/alu_out
# add wave -noupdate /test_cpu/cpu/reg_file/registers
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_read1
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_read2
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_write_id
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_out1
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_out2
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_write_sig
add wave -noupdate /test_cpu/cpu/reg_file/reg_file_write_data
add wave -noupdate /test_cpu/mem/mem_rd
add wave -noupdate /test_cpu/mem/mem_wr
add wave -noupdate /test_cpu/mem/mem_addr
add wave -noupdate /test_cpu/mem/mem_array
add wave -noupdate /test_cpu/mem/mem_wr_data
add wave -noupdate /test_cpu/mem/mem_rd_data
add wave -noupdate /test_cpu/cpu/cpu_control/cpu_ctrl_inst
add wave -noupdate /test_cpu/cpu/cpu_control/inst_op
add wave -noupdate /test_cpu/cpu/cpu_control/funct
add wave -noupdate /test_cpu/cpu/cpu_control/cpu_ctrl_mem_addr_src
add wave -noupdate /test_cpu/cpu/cpu_control/cpu_ctrl_syscall
wave zoom  in 10
# 运行
run 20
