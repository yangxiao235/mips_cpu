module cpu_control(
    // 控制数据通路的信号线
    output reg cpu_ctrl_mem_addr_src, // 内存地址来自alu结果(1)或者pc(0)
    output reg cpu_ctrl_branch, // 短跳
    output reg cpu_ctrl_jmp, // 长跳
output reg cpu_ctrl_reg_dst, // 写寄存器的寄存器编号, 0: 来自rt; 1: 来自rd
    output reg cpu_ctrl_mem_to_reg, // 写寄存器的数据, 0: 数据来自内存, 1: 数据来自alu结果
    output reg cpu_ctrl_reg_write, // 写寄存器
    output reg cpu_ctrl_alu_src, // alu的rt数据来源, 0: 来自寄存器的rt口, 1: 来自指令的立即数扩展
    output reg cpu_ctrl_sign_expand, // 符号扩展, 1: 作符号扩展, 0: 无符号扩展
    output reg cpu_ctrl_mem_read, // 读内存
    output reg cpu_ctrl_mem_write, // 写内存
    // alu的控制线
    output reg [3:0] cpu_ctrl_alu_ctrl,
    // 系统调用
    output reg cpu_ctrl_syscall,
    // 指令
    input [31:0] cpu_ctrl_inst,
    // 程序计数器
    input [31:0] cpu_ctrl_pc
    );
    // alu操作码定义
    parameter ALU_CTRL_ADD = 4'h2;
    parameter ALU_CTRL_SUB = 4'h6;
    parameter ALU_CTRL_AND = 4'h0;
    parameter ALU_CTRL_OR = 4'h1;
    parameter ALU_CTRL_SLT = 4'h7; // 操作码不能简单的用ALU_CTRL_SUB代替, 因为这里可能存在溢出

    initial cpu_ctrl_mem_read = 1; // cpu启动开始读第一条指令
    wire [5:0] inst_op;
    wire [5:0] funct;
    assign inst_op = cpu_ctrl_inst[31:26];
    assign funct = cpu_ctrl_inst[5:0];
    // 取指令
    always @(cpu_ctrl_pc) begin
        cpu_ctrl_mem_read <= 1'b1; // 读取内存
        cpu_ctrl_mem_addr_src <= 0; // 0-取指令:p c_out作为地址; 1-存取数据: alu_out作为地址
        cpu_ctrl_syscall <= 0; // 暂时模拟syscall
    end
    // 指令解码
     always @(cpu_ctrl_inst) begin 
        if (cpu_ctrl_inst == 32'h0) // nop
            {cpu_ctrl_reg_write, cpu_ctrl_mem_addr_src, cpu_ctrl_mem_read, cpu_ctrl_mem_write} <= 7'b0010;
        else begin
            casex (inst_op)
            6'd0  :
                begin
                    casex (funct)
                    6'd32 :

                        begin
                            cpu_ctrl_alu_ctrl <= ALU_CTRL_ADD; // add
                            {
                                cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                                cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                                cpu_ctrl_mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd34 :
                        begin
                            cpu_ctrl_alu_ctrl <= ALU_CTRL_SUB; // sub
                            {
                                cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                                cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                                cpu_ctrl_mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd36 :
                        begin
                            cpu_ctrl_alu_ctrl <= ALU_CTRL_AND; // and
                            {
                                cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                                cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                                cpu_ctrl_mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd37 :
                        begin
                            cpu_ctrl_alu_ctrl <= ALU_CTRL_OR; // or
                            {
                                cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                                cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                                cpu_ctrl_mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd42 :
                        begin
                            cpu_ctrl_alu_ctrl <= ALU_CTRL_SLT; // slt
                            {
                                cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                                cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                                cpu_ctrl_mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd12 :  cpu_ctrl_syscall  <= 1;
                    default : $display($time, ", Unknown alu funct code: %b", funct);
                    endcase
                end // end of 6'd0
            6'd8 :   // addi, 立即数作符号扩展   
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                        cpu_ctrl_mem_write, cpu_ctrl_sign_expand
                    } <= 8'b_011_0000_1;
                    cpu_ctrl_alu_ctrl <= ALU_CTRL_ADD;
                end
            6'd13:   // ori, 立即数作0扩展
                begin
                {
                    cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                    cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                    cpu_ctrl_mem_write, cpu_ctrl_sign_expand
                } <= 8'b_011_0000_0;
                cpu_ctrl_alu_ctrl <= ALU_CTRL_OR;
                end
            6'd35 :  // lw
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                        cpu_ctrl_mem_write, cpu_ctrl_jmp, cpu_ctrl_mem_addr_src,
                        cpu_ctrl_sign_expand
                    } <= 10'b_011_101_001_1;
                end
            6'd43 :  // sw
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                        cpu_ctrl_mem_write, cpu_ctrl_jmp, cpu_ctrl_sign_expand,
                        cpu_ctrl_mem_addr_src
                    } <= 10'b_x01_x01_101_1;
                end
            6'd4  :  // beq, branch由运算结果给出
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_mem_read, cpu_ctrl_mem_write,
                        cpu_ctrl_jmp, cpu_ctrl_branch
                    } <= 7'b_x00_x00_01;
                end
            6'd2  :  // j
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                        cpu_ctrl_mem_write, cpu_ctrl_jmp
                    } <= 8'b_x00_x00_01;
                end
            default : $display($time, ", Unknown opcode: %b", inst_op);
            endcase // casex (inst_op)
        end // end of if(cpu_ctrl_inst == 32'h0)
    end // always @(cpu_ctrl_inst) begin
endmodule