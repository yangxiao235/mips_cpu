module mem;

    reg [7:0] mem_array[7:0];
    reg [7:0] rdata;
    reg rd;
    reg [7:0] addr;
    always @(rd, addr)
        if (rd)
            rdata = mem_array[addr];
    initial begin
        $monitor($time, ", rdata = %d, mem_addr = %d", rdata, addr);
        mem_array[0] = 1;
        mem_array[1] = 2;
        rd = 1;
        addr = 0;
        #5 rdata = 10; $display("rdata change to %d", rdata);
        #20 $stop;

    end
endmodule