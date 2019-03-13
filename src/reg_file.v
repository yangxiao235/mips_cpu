module test_register_file;
    reg[4:0] rid1, rid2;
    reg[4:0] wid;
    reg[31:0] wdata;
    reg clk;
    reg ws;
    wire[31:0] rdata1, rdata2;

    initial begin
        $monitor($time, " , ws = %b, rid1 = %d, rid2 = %d, rdata1 = %d, rdata2 = %d \
    , wid = %d, wdata = %d\n", ws, rid1, rid2, rdata1, rdata2, wid, wdata);
        clk = 0;
        // 测试读
        ws = 0;
        rid1 = 0;  // $zero
        rid2 = 1;
        #1 rid1 = 1; rid2 = 2;
        // 测试写
        ws = 1;
        // (1) 写0号寄存器
        wid = 0;
        wdata = 1234;
        rid1 = 0;
        // (2) 写1号寄存器
        #10 ;
        wid = 1; wdata = 4231; rid1 = 1;
        // 测试读
        #10 ;
        ws = 0; rid1 = 1; rid2 = 4;
        #10 ;
        $finish;
    end
    reg_file regfile(rdata1, rdata2, rid1, rid2, ws, clk, wid, wdata);
    always
        #5 clk = ~clk;
endmodule


module reg_file(
    output reg [31:0] reg_file_out1,
    output reg [31:0] reg_file_out2,
    input[4:0]  reg_file_read1,
    input[4:0]  reg_file_read2,
    input       reg_file_write_sig,
    input       reg_file_clk,
    input[4:0]  reg_file_write_id,
    input[31:0] reg_file_write_data);

    reg[31:0] registers[31:0];
    initial begin
        registers[0] = 0;
        registers[1] = 2;
        registers[2] = 3;
        registers[3] = 5;
        registers[4] = 7;
    end
    // 读寄存器1
    reg dirty;
    always @(reg_file_read1, reg_file_read2, dirty) begin
        reg_file_out1 <= registers[reg_file_read1];
        reg_file_out2 <= registers[reg_file_read2];
        dirty <= 0;
    end
    // 写寄存器
    always @(posedge reg_file_clk)
        if (reg_file_write_sig) begin
            if (reg_file_write_id != 5'h0) begin  // 0号寄存器用于$zero, 不能写
                registers[reg_file_write_id] = reg_file_write_data;
                dirty = 1;
            end
        end
endmodule