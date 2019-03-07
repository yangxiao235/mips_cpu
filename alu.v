module test_alu;
    parameter CTRL_AND = 0;
    parameter CTRL_OR = 1;
    parameter CTRL_ADD = 2;
    parameter CTRL_SUB = 6;
    parameter CTRL_SLT = 7;
    parameter CTRL_NOR = 12;
    reg signed [31:0] alu_in1, alu_in2;
    reg[3:0] ctrl;
    wire signed [31:0]  out; // 打印负数
    wire zero, overflow, carry;

    alu alu(out, zero, overflow, carry, alu_in1, alu_in2, ctrl);
    initial begin
        // 测试and
        alu_in1 =32'b10111;
        alu_in2 =32'b10001;
        ctrl = CTRL_AND;
        #5 $display("and: alu_in1 = %5b, alu_in2 = %5b, out = %5b\n", alu_in1, alu_in2 , out);
        // 测试or
        alu_in1 =32'b10111;
        alu_in2 =32'b10001;
        ctrl = CTRL_OR;
        #5 $display("or: alu_in1 = %5b, alu_in2 = %5b, out = %5b\n", alu_in1, alu_in2 , out);
        // 测试ADD, (1)
        alu_in1 = 1;
        alu_in2 = 2;
        ctrl = CTRL_ADD;
        #5 $display("add: alu_in1 = %d, alu_in2 = %d, out = %d, overflow = %b", alu_in1, alu_in2 , out, overflow);
        // 测试ADD, (2)
        alu_in1 = 1;
        alu_in2 = -2; // 在模拟过程中alu_in2用的是2的补码
        ctrl = CTRL_ADD;
        #5 $display("add: alu_in1 = %d, alu_in2 = %d, out = %d, overflow = %b", alu_in1, alu_in2 , out, overflow);
        // 测试ADD, (3)
        alu_in1 = 32'h8000_0000;
        alu_in2 = 32'h8000_0000;
        ctrl = CTRL_ADD;
        #5 $display("add: alu_in1 = %d(0x%h), alu_in2 = %d(0x%h), out = %d(0x%h), overflow = %b", alu_in1, alu_in1, alu_in2, alu_in2, out, out, overflow);
        // 测试SUB, (1)
        alu_in1 = 2;
        alu_in2 = 1;
        ctrl = CTRL_SUB;
        #5 $display("sub: alu_in1 = %d, alu_in2 = %d, out = %d, overflow = %b", alu_in1, alu_in2 , out, overflow);
        // 测试SUB, (2)
        alu_in1 = 1;
        alu_in2 = -2;
        ctrl = CTRL_SUB;
        #5 $display("sub: alu_in1 = %d, alu_in2 = %d, out = %d, overflow = %b", alu_in1, alu_in2 , out, overflow);
        // 测试零标志, (1)
        alu_in1 = 0;
        alu_in2 = 0;
        ctrl = CTRL_OR;
        #5 $display("zero flag: alu_in1 = %d, alu_in2 = %d, zero = %b",alu_in1, alu_in2, zero);
        // 测试零标志, (2)
        alu_in1 = -1;
        alu_in2 = 0;
        ctrl = CTRL_OR;
        #5 $display("zero flag: alu_in1 = %d, alu_in2 = %d, zero = %b",alu_in1, alu_in2, zero);
        // 测试slt, (1)
        alu_in1 = 1;
        alu_in2 = 1;
        ctrl = CTRL_SLT;
        #5 $display("slt: alu_in1 = %d, alu_in2 = %d, out = %d", alu_in1, alu_in2, out);
        // 测试slt, (2)
        alu_in1 = -3;
        alu_in2 = -2;
        ctrl = CTRL_SLT;
        #5 $display("slt: alu_in1 = %d, alu_in2 = %d, out = %d", alu_in1, alu_in2, out);
        // 测试slt, (3)
        alu_in1 = -3;
        alu_in2 = 2;
        ctrl = CTRL_SLT;
        #5 $display("slt: alu_in1 = %d, alu_in2 = %d, out = %d", alu_in1, alu_in2, out);
        // 测试nor
        alu_in1 = 32'b0010;
        alu_in2 = 32'b1100;
        ctrl = CTRL_NOR;
        #5 $display("nor: alu_in1 = %4b, alu_in2 = %4b, out = %4b", alu_in1, alu_in2, out);
        #10 $stop;
    end

endmodule



// ALU的功能有: add, sub, and, or, slt, nor
// 注意: verilog认为算术操作数是无符号的!
// Any of the following yield an unsigned value:
// (1). Any operation on two operands, unless both operands are signed.
// (2). Based numbers (e.g. 12′d10), unless the explicit “s” modifier is used), 如-4'd2经过verilog编译后转化为2的补码4'd14
// (3). Bit-select results
// (4). Part-select results
// (5). Concatenations

// TODO:
// subu-无符号减法的实现:
// 对于无符号减法, 在alu_in1 >= alu_in2的情况下, alu_out正确
// sltu-无符号版本的slt:
// 参考无符号减法的实现
module alu(
    output reg[31:0]  alu_out, // 运算结果
    output alu_zero,  // 零标志
    output reg alu_overflow, // 溢出位
    output reg alu_carry, // 进位位
    input[31:0] alu_in1,
    input[31:0] alu_in2,
    input[3:0]  alu_ctrl); // 控制线

    assign alu_zero = (alu_in1 == alu_in2) ? 1 : 0;
    reg  alu_carry31;
    reg [30:0] alu_out31;
    always @(alu_ctrl, alu_in1, alu_in2)
        case (alu_ctrl)
            0:  alu_out <= alu_in1 & alu_in2; // and
            1:  alu_out <= alu_in1 | alu_in2; // or
            2:  begin // add
                    // 这几步需要顺序执行, 因为alu_overflow依赖alu_out
                    {alu_carry, alu_out} = alu_in1 + alu_in2;
                    alu_overflow = (alu_in1[31] == alu_in2[31]) ? (alu_out[31] != alu_in1[31]) : 0;
                end
            6:  begin  // sub
                    // 这几步需要顺序执行, 因为alu_overflow依赖alu_out
                    {alu_carry, alu_out} <= alu_in1 - alu_in2;
                    if (alu_in1[31] != alu_in2[31])
                        alu_overflow = (alu_in1[31] != alu_out[31]);
                    else
                        alu_overflow = 0;
                end
            // 对于有符号数大小的比较: 若异号, alu_in符号为0, out=1
            // 否则, 说明同号. 若为负, alu_in绝对值较大, out=1; 若为正, alu_in绝对值小, out=1.
            // verilog中视 a < b 为无符号数的比较
            7:  alu_out <= (alu_in1[31] ^ alu_in2[31]) ? (alu_in1[31] ? 1 : 0) : (alu_in1[31] ? (~alu_in1 > ~alu_in2) : (alu_in1 < alu_in2)); // slt
            12: alu_out <= ~(alu_in1 | alu_in2); // nor
            default: alu_out <= 0;
        endcase

endmodule