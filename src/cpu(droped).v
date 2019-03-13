`include "alu.v"
`include "mem.v"
`include "reg_file.v"
`include "sign_extend.v"

`ifndef  DEBUG_CPU_STATGES
`define  DEBUG_CPU_STATGES 1
`endif
module test_cpu;
    reg clk;
    initial
        clk = 0;
    always
        #5 clk = ~clk;
    cpu cpu(clk);
endmodule

module cpu(input wire clk);
    initial begin
        if (`DEBUG_CPU_STATGES) begin
        $monitor($time, " , pc = %x, inst = %x, reg_rid1 = %x, reg_rid2 = %x, \
reg_wid = %x, reg_wdata = %d, alu_in1 = %h, alu_in2 = %h, alu_out = %h, mem_rdata = %h\n"
            , pc, inst, inst[25:21], inst[20:16], inst[15:11], reg_wdata
            , alu.alu_in1, alu.alu_in2, alu.alu_out, mem_rdata);
        end
    end

    // 0. pc
    parameter INST_DECODE_DELAY = 2; // 模拟解码延迟, 延迟远远小于一个时钟周期
    reg [31:0] pc;
    initial pc = 32'h0;
    reg [31:0] jmp_addr; // 跳转地址
    reg branch; // 短跳
    reg jump; // 长跳
    wire [31:0] pc4;
    assign pc4 = pc + pc4 ;
    always  @(clk) begin
        if (branch)
            pc <= pc + 4 + jmp_addr;
        if (jump)
            pc <= {pc4[31:28], jmp_addr[27:0]};
        if (~branch && ~jump)
            pc <= pc + 4; // 顺序执行
    end
    // 1. 取指令, 指令解码
    parameter INST_OP_ADD = 6'd0;
    parameter INST_OP_SUB = 6'd0;
    parameter INST_OP_AND = 6'd0;
    parameter INST_OP_SLT = 6'd0;
    parameter INST_OP_OR = 6'd0;
    parameter INST_OP_LW = 6'd35;
    parameter INST_OP_SW = 6'd43;
    parameter INST_OP_BEQ = 6'd4;
    parameter INST_OP_JMP = 6'd2;
    parameter INST_OP_TYPE_R = 6'h0;

    parameter ALU_CTRL_ADD = 4'h2;
    parameter ALU_CTRL_SUB = 4'h6;
    parameter ALU_CTRL_AND = 4'h0;
    parameter ALU_CTRL_OR = 4'h1;
    parameter ALU_CTRL_SLT = 4'h7; // 操作码不能简单的用ALU_CTRL_SUB代替, 因为这里可能存在溢出
    reg [31:0] inst;
    wire [31:0] mem_rdata;
    reg mem_rd; // 读内存使能
    reg mem_wr; // 写内存使能
    reg mem_rst; // 复位内存
    reg mem_dump; // 内存备份
    wire [31:0] mem_wdata; // 写内存数据
    reg [31:0] mem_addr;
    // 模拟解码指令延迟
    // clk上升沿时刻, 如果解码没有延迟而立即出现在数据线上的话, 上一个指令的控制线将被新的指令控制线覆盖.
    // 考虑指令序列: (1) add $s3, $s1, $s2
    //              (2) add $s1, $s2, $s3
    // 在(1)指令被执行完后, 下一个时钟上升沿即将到来, 而到来的时钟沿将触发寄存器文件将(1)指令的结果写回
    // 寄存器$s3, 与此同时到来的时钟沿也将触发pc更新, 这将导致新指令的解码. 如果解码立即出现, 而此刻正要将
    // 上一指令结果写回的话, 可能写回的结果的新指令解码的结果.
    // 所以, 有必要严格区分指令解码和寄存器写回的先后时序. 假定在时钟上升沿到来后, 解码需要一定的延迟解码指令
    // 才会出现在数据线上, 而这时上一次的状态将不会被覆盖, 从而寄存器文件可以在上升沿到来后的一小段时间将ALU
    // 运算结果写回寄存器文件.
    // 写内存地址

    mem mem(.mem_rd_data(mem_rdata), .mem_addr(mem_addr), .mem_rd(mem_rd)
        , .mem_wr(mem_wr), .mem_wr_data(mem_wdata), .mem_clk(clk)
        , .mem_rst(mem_rst), .mem_dump(mem_dump));
    // 控制内存读写数据流向的信号
    //          | mem_addr_mux | mem_data_mux
    // 开始解码  | pc           |  inst
    // lw       | alu_out      |  data
    // sw       | alu_out      |  data
    // 确定内存地址
    wire mem_addr_mux; // 0-内存地址来自pc; 1-内存地址来自alu_out
    wire [31:0] alu_out;
    always @(mem_addr_mux, pc, alu_out) begin
        if (mem_addr_mux)
            mem_addr <= alu_out;
        else begin
            mem_addr <= #INST_DECODE_DELAY pc; // 延迟解码, 以便上个指令的结果可能
                                               // 写回寄存器
            mem_rd <= #INST_DECODE_DELAY 1; // 延迟取指令
        end
    end // end of always
    // 读内存数据
    reg [31:0] reg_wdata;
    wire mem_data_mux; // 0-数据为指令; 1-普通数据
    assign #INST_DECODE_DELAY inst = mem_rdata;
    always @(mem_data_mux, mem_rdata) begin
        if (mem_data_mux)
            reg_wdata <= mem_rdata; // 普通数据, 读到寄存器
        else begin
            inst <= mem_rdata; // 指令, 进行解码
        end
    end

    assign inst_op = inst[31:26]; // 指令操作码op

    reg [15:0] imm16; // I型指令的常量
    // 控制线
    reg reg_dst; // 寄存器文件写id来源选择, 0:来自指令的Rt, 1: 来自指令的Rd
    reg reg_write; // 寄存器文件写使能
    reg alu_src; // alu 2号口数据来源选择, 0: 来自寄存器文件2号口; 1: 来自指令16立即数的32位符号扩展
    reg mem_to_reg; // 寄存器文件写数据来源选择, 0:来自内存; 1:来自alu结果
    reg lbranch; // 长跳, pc跳到: {(pc + 4)[31:28], jmp_addr, 2'b00}
    reg mem_read; // 内存读使能
    reg mem_write; // 内存写使能
    reg [3:0] alu_ctrl; // alu功能码: add/sub/and/or

    always @(mem_read)
        mem_rd <= mem_read;
    always @(mem_write)
        mem_wr <= mem_write;

    always @(inst) begin // 指令解码
        casex (inst_op)
        6'd0  :
            begin
                {reg_dst, reg_write, alu_src, mem_to_reg, branch, mem_read, mem_write} <=
                    7'b110_0000;
                casex (inst[5:0]) // funct
                6'd32 :  alu_ctrl <= ALU_CTRL_ADD; // add
                6'd34 :  alu_ctrl <= ALU_CTRL_SUB; // sub
                6'd36 :  alu_ctrl <= ALU_CTRL_AND; // and
                6'd37 :  alu_ctrl <= ALU_CTRL_OR; // or
                6'd42 :  alu_ctrl <= ALU_CTRL_SLT; // slt
                default : $display("Unknown alu ctrl code: %b", alu_ctrl);
                endcase
            end
        6'd35 :  // lw
            begin
                imm16 <= inst[15:0];
                {reg_dst, reg_write, alu_src, mem_to_reg, branch, mem_read, mem_write, jump} <=
                    7'b011_10100;
            end
        6'd43 :  // sw
            begin
                imm16 <= inst[15:0];
                {reg_dst, reg_write, alu_src, mem_to_reg, branch, mem_read, mem_write, jump} <=
                    7'bx01_x0010;
            end
        6'd4  :  // beq, branch由运算结果给出
            begin
                jmp_addr <= imm16 << 2; // 短跳
                {reg_dst, reg_write, alu_src, mem_to_reg, mem_read, mem_write, jump} <=
                    7'bx00_x000;
            end
        6'd2  :  // j
            begin
                jmp_addr <= inst[25:0] << 2; // 长跳
                {reg_dst, reg_write, alu_src, mem_to_reg, branch, mem_read, mem_write, jump} <=
                    7'bx00_x0001;
            end
        default : $display("Unknown opcode: %b", inst_op);
        endcase // casex (inst_op)
    end // always @(inst) begin

    // 寄存器文件
    wire [4:0] reg_rid1, reg_rid2; // 读寄存器1, 读寄存器2
    wire [4:0] reg_wid; // 写寄存器
    wire [31:0] reg_file_out1, reg_file_out2;
    assign reg_rid1 = inst[25:21];
    assign reg_rid2 = inst[20:16];
    assign reg_wid  = reg_dst ? inst[15:11] : inst[20:16];
    reg_file reg_file(.reg_file_out1(reg_file_out1), .reg_file_out2(reg_file_out2)
        , .reg_file_read1(reg_rid1), .reg_file_read2(reg_rid2), .reg_file_wirte_sig(reg_write)
        , .reg_file_clk(clk), .reg_file_write_id(reg_wid), .reg_file_write_data(reg_wdata));

    // alu
    wire [31:0] alu_in2;
    wire [31:0] imm16_extend;
    sign_extend sign_extend(imm16_extend, imm16);
    assign alu_in2 = alu_src ? imm16_extend : reg_file_out2;
    wire alu_zero;
    alu alu(.alu_out(alu_out), .alu_zero(alu_zero), .alu_overflow(alu_overflow)
        , .alu_carry(alu_carry), .alu_in1(reg_file_out1), .alu_in2(alu_in2)
        , .alu_ctrl(alu_ctrl));

    // data meomory
    wire [31:0] dmem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire dmem_rd;
    wire dmem_wr;
    wire dmem_rst;
    wire dmem_dump;
    assign dmem_addr = alu_out;
    mem dmem(.mem_rd_data(dmem_rdata), .mem_addr(dmem_addr), .mem_rd(dmem_rd), .mem_wr(dmem_wr)
        ,.mem_wr_data(dmem_wdata), .mem_clk(clk), .mem_rst(dmem_rst), .mem_dump(dmem_dump));
    assign reg_wdata = mem_to_reg ? alu_out : dmem_rdata;
    assign dmem_rd = mem_read;
    assign dmem_wr = mem_write;
    assign dmem_wdata = reg_file_out2;

endmodule // end of module cpu.