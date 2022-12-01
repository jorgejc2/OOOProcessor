`ifndef debug_itf
`define debug_itf

interface debug_itf;
import rv32i_types::*;
// bit clk, reset_n;

/* ir signals */
// logic instr_mem_resp, instr_read;
// logic [31:0] in;
// rv32i_word instr_mem_address;
logic [31:0] pc_calc;
logic ir_ld_pc;

/* iq signals */
logic res1_empty, res2_empty, res3_empty, res4_empty, rob_load, res1_load, res2_load, res3_load, res4_load, resbr_empty, resbr_load;
logic regfile_allocate;
tomasula_types::ctl_word control_o;

/* res1 signals */
logic res1_exec;
tomasula_types::alu_word res1_alu_out;
logic res1_jalr_executed;
logic res1_pc_to_cdb;
logic res1_update_br;

/* res2 signals */
logic res2_exec;
tomasula_types::alu_word res2_alu_out;
logic res2_jalr_executed;
logic res2_pc_to_cdb;
logic res2_update_br;

/* res3 signals */
logic res3_exec;
tomasula_types::alu_word res3_alu_out;
logic res3_jalr_executed;
logic res3_pc_to_cdb;
logic res3_update_br;

/* res4 signals */
logic res4_exec;
tomasula_types::alu_word res4_alu_out;
logic res4_jalr_executed;
logic res4_pc_to_cdb;
logic res4_update_br;


/* resbr signals */
logic resbr_exec;
tomasula_types::alu_word resbr_alu_out;
logic resbr_jalr_executed;
logic resbr_pc_to_cdb;
logic resbr_update_br;

/* comparator logic */
logic taken;

/* regfile signals */
logic [31:0] reg_src1_data, reg_src2_data, regfile_data_out;
logic src1_valid, src2_valid;
logic [2:0] tag_a, tag_b;
// logic [31:0] reg_a, reg_b;
// logic valid_a, valid_b;

/* rob signals */
// logic robs_calculated[8];
logic rob_ld_pc, regfile_load, rob_full, ld_commit_sel, data_read, data_write, flush_in_prog;
logic [7:0] status_rob_valid, allocated_rob_entries;
logic set_rob_valid[8];
logic [2:0] curr_ptr, head_ptr, br_ptr, br_flush_ptr;
logic [4:0] rd_commit, st_src_commit;
logic rob_reallocate_reg_tags;
tomasula_types::op_t commit_type;

/* cdb signals */
tomasula_types::cdb_data cdb_in[8];
tomasula_types::cdb_data cdb_out[8];

/* alu outputs */
tomasula_types::cdb_data alu1_calculation;
tomasula_types::cdb_data alu2_calculation;
tomasula_types::cdb_data alu3_calculation;
tomasula_types::cdb_data alu4_calculation;
// tomasula_types::cdb_data alu5_calculation;

/* mux logic */
logic [31:0] pc_in;

endinterface : debug_itf

`endif
