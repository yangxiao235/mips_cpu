module  test_pc;
    reg clk;
    reg[31:0] in;
    reg wsignal;
    wire[31:0] out;
    initial begin
        clk = 0;
        in = 32'h10AF;
        wsignal = 0;
        #6 $display("in = %X, out = %X", in, out);
        #6 $display("in = %X, out = %X", in, out);
        #6 $display("in = %X, out = %X", in, out);
        #0 wsignal = 1;
        #6 $display("in = %X, out = %X", in, out);
        #0 wsignal = 0;
        #6 $display("in = %X, out = %X", in, out);
        #6 $display("in = %X, out = %X", in, out);
        #20 $stop;
    end

    pc pc(out, in, clk, wsignal);
    always
        #5 clk = ~clk;
endmodule

module pc(pc_out, pc_new_value, pc_clk, pc_write_sig);
    output reg[31:0] pc_out;
    input[31:0] pc_new_value;
    input  pc_clk;
    input pc_write_sig;


    always @(negedge pc_clk)
        if (pc_write_sig)
            pc_out <= pc_new_value;
        else
            pc_out <= pc_out + 4;
    initial
        pc_out = 32'b0;
endmodule