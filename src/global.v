`ifndef GLOBAL
`define GLOBAL

`define DEBUG_CPU 0
`define SORT 1

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

`define  WAIT_CLK_COUNT  2


`endif // global.v