
`include "global.v"

module test_mem;
    wire[31:0] rdata;
    reg [31:0] wdata;
    reg[31:0] addr;
    reg wr, rd, rst, dump;
    reg clk;

    initial clk = 0;
    always
        #1 clk = ~clk;

    // 测试读: 给出地址, 使能mem_rd

    // 测试写: 给出地址, 写数据, 使能mem_wr

    // 测试复位: 使能rst

    // 测试备份: 使能dump

endmodule

// Memory具有的功能:
// 1. 读: RD有效时, 读数据出现在mem_array[address]上
// 2. 写: WR有效, 且在时钟clk的上升边缘触发写操作mem_array[address] = wdata
// 3. 初始化: 初始化内存内容, 将文件data.dat读入mem_array
// 4. 复位: 将文件mem.dat读入mem_array
// 5. 备份: DUMP在上升沿触发dump操作, 即将当前内存镜像到文件
// Note:
// (1) lw, sw only reads word-aligned requests: 0x0, 0x04, 0x08, 0x0c...(the last two bits are always 0)
// (2)
module mem(mem_rd_data, mem_addr, mem_rd, mem_wr, mem_wr_data, mem_clk, mem_rst, mem_dump);
    output reg [31:0] mem_rd_data;
    input [31:0] mem_addr; // 4的倍数, 是字节地址, 如0x00 - 第0号字节开始的1个word, 0x04-第4号字节开始的1个word
    input [31:0] mem_wr_data;
    input mem_rd, mem_wr, mem_clk;
    input mem_rst, mem_dump;

    parameter MEM_SIZE = 256; // 256 words = 1024 Bytes
    reg [31:0] mem_array[0 : MEM_SIZE - 1];
    // 读数据
    always @(mem_rd, mem_addr) begin
        if (mem_rd)
            mem_rd_data = mem_array[mem_addr[9:2]]; // [1:0]没有意义, 因为是按照4的倍数寻址的
    end
    // 写数据
    always @(posedge mem_clk)
        if (mem_wr)
            mem_array[mem_addr[9:2]] = mem_wr_data;
    // 复位
    always @(posedge mem_rst)
        $readmemh(`MEM_DATA_FILE, mem_array);
    // 备份
    integer ret; // 系统调用返回值
    integer i;
    always @(posedge mem_dump) begin
        ret = $fopen("dump.dat");
        if (ret == 0) begin
            $display("$fopen of dump.dat failed.");
            $stop;
        end
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            $fdisplay(ret, "%b", mem_array[i]);
        end
    end
endmodule