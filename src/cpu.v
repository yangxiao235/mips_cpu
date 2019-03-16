`include  "pc.v"
`include  "reg_file.v"
`include  "sign_extend.v"
`include  "alu.v"

// cpu_addr: 读入cpu或写入内存的内存单元地址, 每次读出或者写入内存的大小为1个字(4 bytes)
// cpu_rd: cpu读内存信号
//
module cpu(cpu_data_out_bus, cpu_data_in_bus, cpu_addr_bus, cpu_rd, cpu_wr, cpu_clk, cpu_en);
    output [31:0] cpu_data_out_bus; // 入数据线, cpu写入内存的数据, 1 word
    output [31:0] cpu_addr_bus; //地址总线, 读入cpu或写入内存的内存单元地址, 每次读出或者写入内存的大小为1个字(4 bytes)
    output cpu_rd; // cpu读内存信号, 数据从cpu_data_in_bus读入
    output cpu_wr; // cpu写内存信号, 写数据在cpu_data_out_bus
    input  [31:0] cpu_data_in_bus;  // 出数据线, cpu从内存中读入的数据, 1 word
    input  cpu_clk;
    input  cpu_en; // cpu使能

// constants
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
// alu ports
    wire [31:0] alu_out;
    wire alu_zero;
    wire alu_overflow;
    wire alu_carry;
    wire [31:0] alu_in1;
    wire [31:0] alu_in2;
    reg [3:0]  alu_ctrl;

// regfile ports
    wire [31:0] reg_file_out1;
    wire [31:0] reg_file_out2;
    wire [31:0] reg_file_write_data;
    wire [4:0] reg_file_read1;
    wire [4:0] reg_file_read2;
    wire [4:0] reg_file_write_id;
    wire reg_file_write_sig;
    wire reg_file_clk;

// sign extends ports
    wire [31:0] sign_ext_out;
    wire [15:0] sign_ext_in;
    wire sign_ext;

// pc ports
    wire [31:0] pc_out;
    wire pc_branch; // 短跳, 短跳的offset_addr是I型指令的低16位
    wire pc_jmp; // 长跳, 长跳的offset_addr是J型指令的低26位
    wire [31:0] pc_offset_addr;
    wire pc_clk;

// ctrl
    reg reg_dst; // 寄存器文件写id来源选择, 0:来自指令的Rt, 1: 来自指令的Rd
    reg reg_write; // 寄存器文件写使能
    reg alu_src; // alu 2号口数据来源选择, 0: 来自寄存器文件2号口; 1: 来自指令16立即数的32位符号扩展
    reg mem_to_reg; // 寄存器文件写数据来源选择, 0:来自内存; 1:来自alu结果
    reg branch; // 短跳, pc跳到{pc + 4 + imm16 << 2}
    reg jump; // 长跳, pc跳到: {(pc + 4)[31:28], imm26 << 2, 2'b00}
    reg mem_read; // 内存读使能
    reg mem_write; // 内存写使能
    reg sign_expand; // 16位扩展为32位. 1-符号扩展, 0-0扩展
    reg syscall; // 系统调用
// sign extend
    assign  sign_ext = sign_expand;

// renaming
    assign clk = ~cpu_en | cpu_clk;
    assign pc_clk = clk;
    assign reg_file_clk = clk;
    assign cpu_rd = mem_read;
    initial mem_read = 1; // cpu启动开始读第一条指令
    assign cpu_wr = mem_write;

    reg [31:0] inst;
    wire [5:0] inst_op;
    wire [5:0] funct;
    wire [5:0] rs, rt, rd;
    wire [15:0] imm16;
    wire [25:0] imm26;
    reg addr_src; // cpu_data_in_bus = 1为数据, = 0为指令
    reg mem_addr_src; // 地址来自pc_out(0)或者来自alu_out(1)
    reg inst_ready;
    assign inst_op = inst[31:26];
    assign imm16 = inst[15:0];
    assign imm26 = inst[25:0];
    assign funct = inst[5:0];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];

    // 取指令
    // (1) 如果当前执行的指令是lw, 那么inst在这期间会受lw影响, 但是inst仅在时钟上升沿有作用,
    // 到时钟上升沿时, inst将被下一条指令刷新, 所以影响无关紧要
    // (2) 对于INST_DECODE_DELAY, 考虑当前执行的指令为lw $s1, ($s1).
    // 由于寄存器文件也在时钟上升沿写入数据, 但是与此同时下一条指令也将会
    // 立即被解码, 当前指令可能无法写回数据就被下一条指令改变了控制状态
    // 增加一小段延迟, 将这两个时间点分开.
    // 仅仅解码在时钟上升沿后需要小段时间,其他写操作假定在时钟上升沿发生后立即写入.
    // 延迟功能在pc模块实现.
    always @(pc_out) begin   // 取指令
        mem_read = 1'b1;   // 读取内存
        addr_src = 0; // 0-取指令:p c_out作为地址; 1-存取数据: alu_out作为地址
        #1 inst = cpu_data_in_bus;
    end

    assign cpu_addr_bus = addr_src ? alu_out : pc_out; // 取指令或者取数据
    // 跳转指令
    assign pc_branch = branch ? alu_zero : 0;
    assign pc_jmp = jump;
    assign pc_offset_addr = branch ? sign_ext_out : (jump ? imm26 : 32'hx);
    // 寄存器文件
    assign reg_file_read1 = rs;
    assign reg_file_read2 = rt;
    assign reg_file_write_sig = reg_write;
    assign reg_file_write_id = reg_dst ? rd : rt;
    assign reg_file_write_data = mem_to_reg ?  cpu_data_in_bus : alu_out;
    assign cpu_data_out_bus = reg_file_out2; // lw $s1, 0($s2)
    // alu
    assign alu_in1 = reg_file_out1;
    assign alu_in2 = alu_src ? sign_ext_out : reg_file_out2;

    pc pc(.pc_out(pc_out), .pc_branch(pc_branch), .pc_jmp(pc_jmp), .pc_offset_addr(pc_offset_addr), .pc_clk(pc_clk));
    // 指令解码
     always @(inst) begin // 指令解码
        if (inst == 32'h0) // nop
            {reg_write, branch, mem_read, mem_write} <=
                        7'b0010;
        else begin
            casex (inst_op)
            6'd0  :
                begin
                    casex (funct)
                    6'd32 :

                        begin
                            alu_ctrl <= ALU_CTRL_ADD; // add
                            {
                                reg_dst, reg_write, alu_src,
                                mem_to_reg, branch, mem_read,
                                mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd34 :
                        begin
                            alu_ctrl <= ALU_CTRL_SUB; // sub
                            {
                                reg_dst, reg_write, alu_src,
                                mem_to_reg, branch, mem_read,
                                mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd36 :
                        begin
                            alu_ctrl <= ALU_CTRL_AND; // and
                            {
                                reg_dst, reg_write, alu_src,
                                mem_to_reg, branch, mem_read,
                                mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd37 :
                        begin
                            alu_ctrl <= ALU_CTRL_OR; // or
                            {
                                reg_dst, reg_write, alu_src,
                                mem_to_reg, branch, mem_read,
                                mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd42 :
                        begin
                            alu_ctrl <= ALU_CTRL_SLT; // slt
                            {
                                reg_dst, reg_write, alu_src,
                                mem_to_reg, branch, mem_read,
                                mem_write
                            } <= 7'b_110_000_0;
                        end
                    6'd12 :  syscall  <= 1;
                    default : $display("Unknown alu funct code: %b", funct);
                    endcase
                end // end of 6'd0
            6'd8 :   // addi, 立即数作符号扩展    // sys
                begin
                    {
                        reg_dst, reg_write, alu_src,
                        mem_to_reg, branch, mem_read,
                        mem_write, sign_expand
                    } <= 8'b_011_0000_1;
                    alu_ctrl <= ALU_CTRL_ADD;
                end
            6'd13:   // ori, 立即数作0扩展
                begin
                {
                    reg_dst, reg_write, alu_src,
                    mem_to_reg, branch, mem_read,
                    mem_write, sign_expand
                } <= 8'b_011_0000_0;
                alu_ctrl <= ALU_CTRL_OR;
                end
            6'd35 :  // lw
                begin
                    {
                        reg_dst, reg_write, alu_src,
                        mem_to_reg, branch, mem_read,
                        mem_write, jump, addr_src,
                        sign_expand
                    } <= 10'b_011_101_001_1;
                end
            6'd43 :  // sw
                begin
                    {
                        reg_dst, reg_write, alu_src,
                        mem_to_reg, branch, mem_read,
                        mem_write, jump, sign_expand,
                        addr_src
                    } <= 10'b_x01_x01_101_1;
                end
            6'd4  :  // beq, branch由运算结果给出
                begin
                    {
                        reg_dst, reg_write, alu_src,
                        mem_to_reg, mem_read, mem_write,
                        jump, branch
                    } <= 7'b_x00_x00_01;
                end
            6'd2  :  // j
                begin
                    {
                        reg_dst, reg_write, alu_src,
                        mem_to_reg, branch, mem_read,
                        mem_write, jump, branch
                    } <= 8'b_x00_x00_010;
                end
            default : $display("Unknown opcode: %b", inst_op);
            endcase // casex (inst_op)
        end // end of if(inst == 32'h0)
    end // always @(inst) begin

    // 系统调用syscall指令
    // $v0: 存放例程编号
    // $a0~$a1: 存放例程参数
    wire signed [31:0] signed_a0 = reg_file.registers[4];
    always @(syscall) begin
        if (syscall) begin
            syscall <= 0;
            casex(reg_file.registers[2])  // $v0
            1 :     // print integer, $a0保存整数
                $write(">>%d\n",signed_a0); // $a0为4号寄存器
            4 :     // print null-terminated string, $a0保存首地址
                $write(">>%s\n", mem.mem_array[reg_file.registers[4]]);
            11 :    // print character, $a0保存字符
                $write(">>%c\n", reg_file.registers[4]);
            34 :    // print integer in hex
                $write(">>%x\n", reg_file.registers[4]);
            35 :    // print integer in binary
                $write(">>%b\n", reg_file.registers[4]);
            36 :    // print integer as unsigned
                $write(">>%d\n", reg_file.registers[4]);
            10 : // 退出模拟
                begin
                    $display(">>Program terminated.");
                    $stop;
                end
            default: $display(">>Syscall service %d is not implementd now.", reg_file.registers[2]);
            endcase


        end
    end

    alu alu(.alu_out(alu_out), .alu_zero(alu_zero), .alu_overflow(alu_overflow)
        , .alu_carry(alu_carry), .alu_in1(alu_in1), .alu_in2(alu_in2)
        , .alu_ctrl(alu_ctrl));

    reg_file reg_file(.reg_file_out1(reg_file_out1), .reg_file_out2(reg_file_out2)
    , .reg_file_read1(reg_file_read1), .reg_file_read2(reg_file_read2), .reg_file_write_sig(reg_file_write_sig)
    , .reg_file_clk(reg_file_clk), .reg_file_write_id(reg_file_write_id), .reg_file_write_data(reg_file_write_data));


    assign sign_ext_in = imm16;
    sign_extend sign_extend(.sign_ext_out(sign_ext_out), .sign_ext_in(sign_ext_in), .sign_ext(sign_ext));



endmodule