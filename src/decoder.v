module decoder(
    // output
    input [5:0] decode_opcode,
    input [5:0] decode_funct,
    input [4:0] decode_rs,
    input [4:0] decode_rt,
    input [4:0] decode_rd,
    input [15:0] decode_imm16,
    input [25:0] decode_jmp_target,
    input [4:0] decode_shamt,
    // input
    output [31:0] decode_inst
);
    assign decode_opcode = decode_inst[31:26];
    assign decode_imm16 = decode_inst[15:0];
    assign decode_jmp_target = decode_inst[25:0];
    assign decode_funct = decode_inst[5:0];
    assign decode_rs = decode_inst[25:21];
    assign decode_rt = decode_inst[20:16];
    assign decode_rd = decode_inst[15:11];
    assign decode_shamt = decode_inst[10:6];

endmodule