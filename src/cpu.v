`include  "pc.v"
`include  "reg_file.v"
`include  "sign_extend.v"
`include  "alu.v"
`include  "cpu_control.v"
`include  "decoder.v"

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
    wire [3:0]  alu_ctrl;

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

// cpu control ports
    wire cpu_ctrl_mem_addr_src;
    wire cpu_ctrl_branch;  
    wire cpu_ctrl_jmp;
    wire cpu_ctrl_reg_dst;  
    wire cpu_ctrl_mem_to_reg; 
    wire cpu_ctrl_reg_write; 
    wire cpu_ctrl_alu_src;  
    wire cpu_ctrl_sign_expand;
    wire  cpu_ctrl_mem_read; 
    wire cpu_ctrl_mem_write; 
    wire [3:0] cpu_ctrl_alu_ctrl;
    wire cpu_ctrl_syscall;
    wire [31:0] cpu_ctrl_inst;

// decoder ports
    wire [5:0] decode_opcode;
    wire [5:0] decode_funct;
    wire [4:0] decode_rs;
    wire [4:0] decode_rt;
    wire [4:0] decode_rd;
    wire [15:0] decode_imm16;
    wire [25:0] decode_jmp_target;
    wire [4:0] decode_shamt;
    wire [31:0] decode_inst;
// 时钟
    assign clk = ~cpu_en | cpu_clk;
    assign pc_clk = clk;
    assign reg_file_clk = clk;
    assign cpu_rd = cpu_ctrl_mem_read;
    assign cpu_wr = cpu_ctrl_mem_write;

    // 取指令
    // (1) 如果当前执行的指令是lw, 那么inst在这期间会受lw影响, 但是inst仅在时钟上升沿有作用,
    // 到时钟上升沿时, inst将被下一条指令刷新, 所以影响无关紧要
    // (2) 对于INST_DECODE_DELAY, 考虑当前执行的指令为lw $s1, ($s1).
    // 由于寄存器文件也在时钟上升沿写入数据, 但是与此同时下一条指令也将会
    // 立即被解码, 当前指令可能无法写回数据就被下一条指令改变了控制状态
    // 增加一小段延迟, 将这两个时间点分开.
    // 仅仅解码在时钟上升沿后需要小段时间,其他写操作假定在时钟上升沿发生后立即写入.
    // 延迟功能在pc模块实现.
    reg [31:0] inst;
    always @(pc_out) begin   // 取指令
        #1 inst = cpu_data_in_bus;
    end
    // cpu control
    assign cpu_ctrl_inst = inst;
    // instruction decoder
    assign decode_inst = inst;
    // cpu
    assign cpu_addr_bus = cpu_ctrl_mem_addr_src ? alu_out : pc_out; // 取指令或者取数据
    assign cpu_data_out_bus = reg_file_out2; // lw $s1, 0($s2)
    // 跳转
    assign pc_branch = cpu_ctrl_branch ? alu_zero : 0;
    assign pc_jmp = cpu_ctrl_jmp;
    assign pc_offset_addr = cpu_ctrl_branch ? sign_ext_out : (cpu_ctrl_jmp ? decode_jmp_target : 32'hx);
    // 寄存器文件
    assign reg_file_read1 = decode_rs;
    assign reg_file_read2 = decode_rt;
    assign reg_file_write_sig = cpu_ctrl_reg_write;
    assign reg_file_write_id = cpu_ctrl_reg_dst ? decode_rd : decode_rt;
    assign reg_file_write_data = cpu_ctrl_mem_to_reg ?  cpu_data_in_bus : alu_out;
    // alu
    assign alu_in1 = reg_file_out1;
    assign alu_ctrl = cpu_ctrl_alu_ctrl;
    assign alu_in2 = cpu_ctrl_alu_src ? sign_ext_out : reg_file_out2;
    // 符号扩展
    assign  sign_ext = cpu_ctrl_sign_expand;
    assign sign_ext_in = decode_imm16;
    // 系统调用syscall指令
    // $v0: 存放例程编号
    // $a0~$a1: 存放例程参数
    wire signed [31:0] signed_a0 = reg_file.registers[4];
    always @(cpu_ctrl_syscall) begin
        if (cpu_ctrl_syscall) begin
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

    pc pc(
        .pc_out(pc_out), 
        .pc_branch(pc_branch), 
        .pc_jmp(pc_jmp), 
        .pc_offset_addr(pc_offset_addr), 
        .pc_clk(pc_clk)
    );
    decoder decoder(
        .decode_opcode(decode_opcode),
        .decode_funct(decode_funct),
        .decode_rs(decode_rs),
        .decode_rt(decode_rt),
        .decode_rd(decode_rd),
        .decode_imm16(decode_imm16),
        .decode_jmp_target(decode_jmp_target),
        .decode_shamt(decode_shamt),
        .decode_inst(decode_inst)
    );
    cpu_control cpu_control(
        .cpu_ctrl_mem_addr_src(cpu_ctrl_mem_addr_src),
        .cpu_ctrl_branch(cpu_ctrl_branch),
        .cpu_ctrl_jmp(cpu_ctrl_jmp),
        .cpu_ctrl_reg_dst(cpu_ctrl_reg_dst),
        .cpu_ctrl_mem_to_reg(cpu_ctrl_mem_to_reg),
        .cpu_ctrl_reg_write(cpu_ctrl_reg_write),
        .cpu_ctrl_alu_src(cpu_ctrl_alu_src),
        .cpu_ctrl_sign_expand(cpu_ctrl_sign_expand),
        .cpu_ctrl_mem_read(cpu_ctrl_mem_read),
        .cpu_ctrl_mem_write(cpu_ctrl_mem_write),
        .cpu_ctrl_alu_ctrl(cpu_ctrl_alu_ctrl),
        .cpu_ctrl_syscall(cpu_ctrl_syscall),
        .cpu_ctrl_inst(cpu_ctrl_inst),
        .cpu_ctrl_pc(pc_out)
    );
    alu alu(
        .alu_out(alu_out),
        .alu_zero(alu_zero),
        .alu_overflow(alu_overflow),
        .alu_carry(alu_carry),
        .alu_in1(alu_in1),
        .alu_in2(alu_in2),
        .alu_ctrl(alu_ctrl)
    );
    reg_file reg_file(
        .reg_file_out1(reg_file_out1), 
        .reg_file_out2(reg_file_out2),
        .reg_file_read1(reg_file_read1), 
        .reg_file_read2(reg_file_read2), 
        .reg_file_write_sig(reg_file_write_sig),
        .reg_file_clk(reg_file_clk), 
        .reg_file_write_id(reg_file_write_id), 
        .reg_file_write_data(reg_file_write_data)
    );

    sign_extend sign_extend(.sign_ext_out(sign_ext_out), .sign_ext_in(sign_ext_in), .sign_ext(sign_ext));



endmodule