module cpu_control(
    // ��������ͨ·���ź���
    output reg cpu_ctrl_mem_addr_src, // �ڴ��ַ����alu���(1)����pc(0)
    output reg cpu_ctrl_branch, // ����
    output reg cpu_ctrl_jmp, // ����
output reg cpu_ctrl_reg_dst, // д�Ĵ����ļĴ������, 0: ����rt; 1: ����rd
    output reg cpu_ctrl_mem_to_reg, // д�Ĵ���������, 0: ���������ڴ�, 1: ��������alu���
    output reg cpu_ctrl_reg_write, // д�Ĵ���
    output reg cpu_ctrl_alu_src, // alu��rt������Դ, 0: ���ԼĴ�����rt��, 1: ����ָ�����������չ
    output reg cpu_ctrl_sign_expand, // ������չ, 1: ��������չ, 0: �޷�����չ
    output reg cpu_ctrl_mem_read, // ���ڴ�
    output reg cpu_ctrl_mem_write, // д�ڴ�
    // alu�Ŀ�����
    output reg [3:0] cpu_ctrl_alu_ctrl,
    // ϵͳ����
    output reg cpu_ctrl_syscall,
    // ָ��
    input [31:0] cpu_ctrl_inst,
    // ���������
    input [31:0] cpu_ctrl_pc
    );
    // alu�����붨��
    parameter ALU_CTRL_ADD = 4'h2;
    parameter ALU_CTRL_SUB = 4'h6;
    parameter ALU_CTRL_AND = 4'h0;
    parameter ALU_CTRL_OR = 4'h1;
    parameter ALU_CTRL_SLT = 4'h7; // �����벻�ܼ򵥵���ALU_CTRL_SUB����, ��Ϊ������ܴ������

    initial cpu_ctrl_mem_read = 1; // cpu������ʼ����һ��ָ��
    wire [5:0] inst_op;
    wire [5:0] funct;
    assign inst_op = cpu_ctrl_inst[31:26];
    assign funct = cpu_ctrl_inst[5:0];
    // ȡָ��
    always @(cpu_ctrl_pc) begin
        cpu_ctrl_mem_read <= 1'b1; // ��ȡ�ڴ�
        cpu_ctrl_mem_addr_src <= 0; // 0-ȡָ��:p c_out��Ϊ��ַ; 1-��ȡ����: alu_out��Ϊ��ַ
        cpu_ctrl_syscall <= 0; // ��ʱģ��syscall
    end
    // ָ�����
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
            6'd8 :   // addi, ��������������չ   
                begin
                    {
                        cpu_ctrl_reg_dst, cpu_ctrl_reg_write, cpu_ctrl_alu_src,
                        cpu_ctrl_mem_to_reg, cpu_ctrl_branch, cpu_ctrl_mem_read,
                        cpu_ctrl_mem_write, cpu_ctrl_sign_expand
                    } <= 8'b_011_0000_1;
                    cpu_ctrl_alu_ctrl <= ALU_CTRL_ADD;
                end
            6'd13:   // ori, ��������0��չ
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
            6'd4  :  // beq, branch������������
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