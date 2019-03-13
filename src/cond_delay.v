module condition_delay;
    reg out;
    reg mux;
    reg in1;
    reg in2;

    always @(mux, in1, in2) begin
        if (mux)
            out <= #3 in1;
        else
            out <= in2;
    end

    initial begin
        $monitor($time, ", out = %b, mux = %b, in1 = %b,  in2 = %b", out, mux, in1, in2);
        mux = 0; in1 = 1; in2 = 0; //无延迟输出
        #5 ;
        mux = 1; // 延迟输出
        #5 ;
        mux = 0; // 无延迟输出
        #5 $finish;
    end
endmodule