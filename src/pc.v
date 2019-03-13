module  test_pc;
    reg clk;
    initial clk = 0;
    always
        #2 clk = ~clk;
    wire [31:0] pc_out;
    reg branch, jmp;
    reg [31:0] offset_addr;
    pc pc(pc_out, branch, jmp, offset_addr, clk);
    always begin
        $monitor($time, ", pc = %h, branch = %b, jmp = %b, offset_addr = %h",
            pc_out, branch, jmp, offset_addr);
        // 顺序执行
        #5;
        // 短跳
        branch = 1;
        offset_addr = 32'h0000_0111;
        #3;
        branch = 0;
        if (jmp)
            $display("x is true.");
        // 长跳
        jmp = 1;
        offset_addr = 32'h0000_0001;
        #3;
        jmp = 0;
        #20;
        $finish;
    end

endmodule

module  pc(pc_out, pc_branch, pc_jmp, pc_offset_addr, pc_clk);
    output [31:0] pc_out;
    input  pc_branch; // 短跳, 短跳的offset_addr是I型指令的低16位, 符号已假定扩展
    input  pc_jmp; // 长跳, 长跳的offset_addr是J型指令的低26位
    input  [31:0] pc_offset_addr;
    input  pc_clk;
    // 这个常量的解释见cpu.v
    parameter INST_DECODE_DELAY = 1;

    wire [31:0] pc4;
    reg [31:0] pc;
    initial pc = 32'h0;
    assign pc4 = pc + 4 ;
    assign pc_out = pc;
    wire [31:0] pc_offset_addr_shift2;
    assign pc_offset_addr_shift2 = pc_offset_addr << 2;
    always @(posedge pc_clk) begin
        if (pc_branch)
            pc <= #INST_DECODE_DELAY pc4 + pc_offset_addr_shift2;
        else if (pc_jmp)
            pc <= #INST_DECODE_DELAY {pc4[31:28], pc_offset_addr_shift2[27:0]};
        else
            pc <= #INST_DECODE_DELAY pc4;
    end
endmodule