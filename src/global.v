`ifndef GLOBAL
`define GLOBAL

`define DEBUG 1
`define SORT  1

`ifdef DEBUG
    `ifdef LOGIC
    `define MEM_DATA_FILE  "test/logic.bin.txt"
    `endif

    `ifdef  MAX
    `define MEM_DATA_FILE  "test/max.bin.txt"
    `endif

    `ifdef SUM
    `define MEM_DATA_FILE   "test/sum1to100.bin.txt"
    `endif

    `ifdef SORT
    `define MEM_DATA_FILE   "test/sort.bin.txt"
    `endif
`else
    `define MEM_DATA_FILE   "test/mem.dat"
`endif // `ifdef DEBUG

`endif // global.v