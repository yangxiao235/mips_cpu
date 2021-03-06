module test_sign_extend;
    wire[31:0] data32;
    reg[15:0] data16;
    initial begin
        $monitor($time, ", data16 = %x, data32 = %x\n", data16, data32);
        data16 = 12;
        #5 data16 = -1;
        #5 data16 = -13;
        #5 $stop;
    end
    Sign_extend ext(data32, data16);
endmodule


module sign_extend(sign_ext_out, sign_ext_in, sign_ext);
    output [31:0] sign_ext_out;
    input [15:0] sign_ext_in;
    input  sign_ext; // 0-高位用0扩展; 1-高位用符号扩展
    assign sign_ext_out = sign_ext ? (sign_ext_in[15] ? {16'hffff, sign_ext_in} : {16'h0000, sign_ext_in}) : {16'h0000, sign_ext_in};
endmodule