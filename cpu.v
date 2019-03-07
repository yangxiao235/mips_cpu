`include "alu.v"
`include "memory.v"
`include "register_file.v"
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
        $monitor($time, " , pc = %x, inst = %x, reg_rid1 = %x, reg_rid2 = %x, reg_wid = %x, reg_wdata = %xn",
            pc, inst, inst[25:21], inst[20:16], inst[15:11], reg_file_write_data);
        end
    end
    // 数据通路控制线及储存器件读写控制
    reg reg_dst, branch, mem_to_reg, alu_src;
    reg reg_file_wirte_sig, data_mem_read_sig, data_mem_write_sig;
    // stage 1, fetch instruction
    wire [31:0] inst;
    reg [31:0] pc;
    initial
        pc = 32'h0;
    code_memory code_mem(.code_mem_out(inst), .code_mem_addr(pc));
    wire [31:0] pc4;
    assign pc4 = pc + 4;
    wire [31:0] sign_ext_out;
    sign_extend sign_extend(.sign_ext_out(sign_ext_out), .sign_ext_in(inst[15:0])); // 符号扩展
    wire alu_overflow;
    always @(posedge clk) begin // 时钟上升沿pc改变
        if (branch && alu_overflow)
            pc <= pc4 + sign_ext_out << 2; // beq $s1, $s2, next
        else
            pc <= pc4;
    end
    // stage 2, instruction decode
    parameter INST_OP_ADD = 6'h0;
    parameter INST_OP_SUB = 6'h0;
    parameter INST_OP_AND = 6'h0;
    parameter INST_OP_OR = 6'h0;
    parameter INST_OP_LW = 6'h23;
    parameter INST_OP_SW = 6'h2b;
    parameter INST_OP_BEQ = 6'h4;
    parameter INST_OP_SLT = 6'ha;
    parameter INST_OP_JMP = 6'h2;
    parameter INST_OP_TYPE_R = 6'h0;
    wire [4:0] reg_file_write_id;
    assign reg_file_write_id = reg_dst ? inst[20:16] : inst[15:11];
    wire [31:0] reg_file_out1, reg_file_out2;
    reg reg_file_wite_sig;
    wire [31:0] reg_file_write_data;
    reg_file reg_file(.reg_file_out1(reg_file_out1), .reg_file_out2(reg_file_out2),
        .reg_file_read1(inst[25:21]), .reg_file_read2(inst[20:16]),
        .reg_file_wirte_sig(reg_file_wirte_sig), .reg_file_clk(clk),
        .reg_file_write_id(reg_file_write_id), .reg_file_write_data(reg_file_write_data));

    always @(inst) begin  // inst[31:26] -- op, op决定了指令的类型:R型, I型, J型
        if (inst[31:26] == INST_OP_TYPE_R) begin // R型
            reg_dst <= 1;
            alu_src <= 0;
            mem_to_reg <= 0;
            branch <= 0;
            data_mem_write_sig <= 0;
            data_mem_read_sig <= 0;
            reg_file_wirte_sig <= 1;
        end
        if (inst[31:26] == INST_OP_LW) begin
            reg_dst <= 0;
            alu_src <= 1;
            mem_to_reg <= 1;
            branch <= 0;
            data_mem_write_sig <= 0;
            data_mem_read_sig <= 1;
            reg_file_wirte_sig <= 1;
        end
        if (inst[31:26] == INST_OP_SW) begin
            alu_src <= 1;
            branch <= 0;
            data_mem_write_sig <= 1;
            data_mem_read_sig <= 0;
            reg_file_wirte_sig <= 0;
        end
        if (inst[31:26] == INST_OP_BEQ) begin
            alu_src <= 0;
            branch <= 1;
            data_mem_write_sig <= 0;
            data_mem_read_sig <= 0;
            reg_file_wirte_sig <= 0;
        end
    end

    // stage 3, alu
    wire [31:0] alu_out;
    wire alu_zero;
    reg [3:0] alu_ctrl;
    wire [31:0] alu_in2 = alu_src ? sign_ext_out : reg_file_out2;


    parameter INST_FUNC_ADD = 6'h20;
    parameter INST_FUNC_SUB = 6'h22;
    parameter INST_FUNC_AND = 6'h24;
    parameter INST_FUNC_OR = 6'h25;
    parameter INST_FUNC_SLT = 6'h2a;
    parameter INST_FUNC_UNSPEC = 6'hx;

    parameter ALU_CTRL_ADD = 4'h2;
    parameter ALU_CTRL_SUB = 4'h6;
    parameter ALU_CTRL_AND = 4'h0;
    parameter ALU_CTRL_OR = 4'h1;
    parameter ALU_CTRL_SLT = 4'h7;

    always @(inst) begin // 解码op字段为对应的alu_ctrl字段, inst[5:0] --- funct, inst[31:26] -- op
        if (inst[31:26] == INST_OP_LW || inst[31:26] == INST_OP_SW) // lw, sw
            alu_ctrl <= ALU_CTRL_AND;
        if (inst[31:26] == INST_OP_BEQ) // beq
            alu_ctrl <= ALU_CTRL_SUB;
        if (inst[31:26] == INST_OP_ADD  && inst[31:26] == INST_FUNC_ADD) // add
            alu_ctrl <= ALU_CTRL_ADD;
        if (inst[31:26] == INST_OP_SUB && inst[31:26] ==INST_FUNC_SUB) // sub
            alu_ctrl <= ALU_CTRL_SUB;
        if (inst[31:26] == INST_OP_AND && inst[31:26] == INST_FUNC_AND) // and
            alu_ctrl <= ALU_CTRL_AND;
        if (inst[31:26] == INST_OP_OR && inst[31:26] == INST_FUNC_OR) // or
            alu_ctrl <= ALU_CTRL_OR;
        if (inst[31:26] == INST_OP_SLT && inst[31:26] == INST_FUNC_SLT) // slt
            alu_ctrl <= ALU_CTRL_SLT;
    end
    alu alu(.alu_out(alu_out), .alu_zero(alu_zero), .alu_overflow(alu_overflow), .alu_in1(reg_file_out1), .alu_in2(alu_in2), .alu_ctrl(alu_ctrl));
    // stage 4, memory access
    wire [31:0] data_mem_out;
    data_memory data_mem(.data_mem_out(data_mem_out), .data_mem_write_sig(data_mem_write_sig), .data_mem_read_sig(data_mem_read_sig),
        .data_mem_addr(alu_out), .data_mem_write_data(reg_file_out2));
    // stage 5, write back
    assign reg_file_write_data = mem_to_reg ? data_mem_out : alu_out;

endmodule // end of module cpu.