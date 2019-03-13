// 实验导致overflow的条件
module overflow;
    parameter OP_ADD = 0;
    parameter OP_SUB = 1;
    reg signed [2:0] result;
    reg cout, overflow;
    reg signed [2:0] A, B;
    reg op;
    always @(A, B) begin
    case (op)
        0: 
            begin
                {cout, result} = A + B;
                overflow = (A[2] == B[2]) ? (result[2] != A[2]) : 0;
            end
        1: 
            begin
                {cout, result} = A - B;
                if (A[2] > B[2])  // A为负数, B为正数, 若结果最高位为0, 则发生溢出
                    if (~result[2])
                        overflow = 1;
                    else 
                        overflow = 0;
                else if (A[2] < B[2]) // A为正数, B为负数, 若结果最高位为1, 则发生溢出
                    if (result[2])
                        overflow = 1;
                    else 
                        overflow = 0;
                else 
                    overflow = 0;
            end
    endcase 
    end // end of always
    initial begin
        $monitor($time, ", A = %d(0x%h), B = %d(0x%h), result = %d(0x%h), overflow = %b", A, A, B, B, result, result, overflow);
        op = OP_SUB;
        A = 1;
        B = -2;
        // #10 begin
        // A = 
        
        // end
        #10 $stop;
    end
endmodule