module test_register_file;
    reg[4:0] rid1, rid2;
    reg[4:0] wid;
    reg[31:0] wdata;
    reg clk;
    reg wsignal;
    wire[31:0] data1, data2;

    initial begin
        $monitor($time, " , rid1 = %d, rid2 = %d, read1 = %d, read2 = %d\n", rid1, rid2, data1, data2);
        clk = 0;
        wsignal = 1;
        rid1 = 0;
        rid2 = 0;
        wid = 0;
        wdata = 1;
        #5 wsignal = 0;
        wid = 1;
        wdata = 2;
        rid2 = 1;
        #5 wsignal = 1;
        #100 $stop;
    end
    reg_file regfile(data1, data2, rid1, rid2, wsignal, clk, wid, wdata);
    always
        #5 clk = ~clk;
endmodule


module reg_file(
    output[31:0] reg_file_out1,
    output[31:0] reg_file_out2,
    input[4:0]  reg_file_read1,
    input[4:0]  reg_file_read2,
    input       reg_file_wirte_sig,
    input       reg_file_clk,
    input[4:0]  reg_file_write_id,
    input[31:0] reg_file_write_data);

    reg[31:0] registers[31:0];
    assign reg_file_out1 = registers[reg_file_read1];
    assign reg_file_out2 = registers[reg_file_read2];

    always @(negedge reg_file_clk)
        if (reg_file_wirte_sig == 1) begin
            registers[reg_file_write_id] = reg_file_write_data;
        end
endmodule