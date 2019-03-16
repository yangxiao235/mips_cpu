`include "src/cpu.v"
`include "src/mem.v"
`include "src/sign_extend.v"
`include "src/global.v"
`include "src/pc.v"
`include "src/reg_file.v"

module  test_cpu;
    // cpu ports
    wire  [31:0] cpu_data_out_bus;
    wire  [31:0] cpu_data_in_bus;
    wire  [31:0] cpu_addr_bus;
    wire  cpu_rd;
    wire  cpu_wr;
    wire  cpu_clk;
    reg   cpu_en;
    // mem port
    wire [31:0] mem_rd_data;
    wire [31:0] mem_addr;
    wire [31:0] mem_wr_data;
    wire mem_rd, mem_wr, mem_clk;
    reg mem_rst, mem_dump; // 作为调试之用

    // clk
    reg clk;
    initial clk = 0;
    // cpu
    assign cpu_data_in_bus = mem_rd_data;
    assign cpu_clk = clk;

    // mem
    assign mem_clk = clk;
    assign mem_addr = cpu_addr_bus;
    assign mem_wr_data = cpu_data_out_bus;
    assign mem_wr = cpu_wr;
    assign mem_rd = cpu_rd;

    cpu cpu(.cpu_data_out_bus(cpu_data_out_bus), .cpu_data_in_bus(cpu_data_in_bus)
        , .cpu_addr_bus(cpu_addr_bus), .cpu_rd(cpu_rd), .cpu_wr(cpu_wr), .cpu_clk(cpu_clk), .cpu_en(cpu_en));
    mem mem(.mem_rd_data(mem_rd_data), .mem_addr(mem_addr), .mem_rd(mem_rd), .mem_wr(mem_wr)
        , .mem_wr_data(mem_wr_data), .mem_clk(mem_clk), .mem_rst(mem_rst), .mem_dump(mem_dump));

    always
       #5  clk = ~clk;
    initial begin
        $display("Initializing memory...");
        mem_rst = 1; // 内存初始化
        cpu_en = 0; // cpu停止工作
        #1;
        cpu_en = 1; // cpu开始工作
        // 监视重要参数
        // $monitor($time, ", pc=%h, inst=%h, alu_is=%h, alu_it=%h, alu_out=%h, alu_op= %d",
            // cpu.pc.pc, cpu.inst, cpu.alu.alu_in1, cpu.alu.alu_in2, cpu.alu.alu_out, cpu.alu.alu_ctrl);
    end

    always @(cpu.inst) begin
        if (`DEBUG_CPU) begin
            show_reg_file;
            $display($time, ", count=%d, pc=%h, inst=%h, alu_is=%h, alu_it=%h, alu_out=%h, alu_op= %d",
                cpu.pc.pc/4, cpu.pc.pc, cpu.inst, cpu.alu.alu_in1, cpu.alu.alu_in2, cpu.alu.alu_out, cpu.alu.alu_ctrl);
        end
    end

    integer i;
    task show_reg_file;
    begin
        $display("----Regfile-----");
        for (i = 0; i < 32; i = i+4) begin
            $display("reg %d: %h  %h  %h  %h", i, cpu.reg_file.registers[i]
                , cpu.reg_file.registers[i + 1], cpu.reg_file.registers[i + 2]
                , cpu.reg_file.registers[i + 3]);
        end
    end // end of begin
    endtask


endmodule