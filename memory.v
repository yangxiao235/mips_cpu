
module test_code_memory;
    wire[31:0] data;
    reg[31:0] addr;

    initial begin
        addr = 0;
        #5 $display("addr = %x, data = %b", addr, data);
    end
    code_memory cm(data, addr);
endmodule

module code_memory(code_mem_out, code_mem_addr);
    output[31:0] code_mem_out;
    input[31:0] code_mem_addr;

    reg[7:0] memory[1023:0];  // 主存1kiB大小
    assign code_mem_out = memory[code_mem_addr];
    initial begin
    // 初始化为指令, 作为测试之用
        memory[0] <= 32'b00000000000000010001000000100010;
        memory[4] <= 32'b00000000001000100001100000100100;
        memory[8] <= 32'b00000000010000010011000000100101;
        memory[12] <= 32'b00000001100010010101000000100000;
        memory[16] <= 32'b10001100000000010001000000100000;
        memory[20] <= 32'b10101100000000010001000000100000;
        memory[24] <= 32'b00001000000000010001000000100000;

    end
endmodule

module data_memory(data_mem_out, data_mem_write_sig, data_mem_read_sig, data_mem_addr, data_mem_write_data);
    output[31:0] data_mem_out;
    input data_mem_write_sig, data_mem_read_sig;
    input[31:0] data_mem_write_data;
    input[31:0] data_mem_addr;

    reg[7:0] memory[1023:0];
    assign data_mem_out = (data_mem_read_sig == 1) ? memory[data_mem_addr] : 0;
    always @(negedge data_mem_write_sig) begin
        memory[data_mem_addr] <= data_mem_write_data;
    end
endmodule