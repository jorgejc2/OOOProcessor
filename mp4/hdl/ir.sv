
module ir
import rv32i_types::*;
(
    input clk,
    input rst,
    input instr_mem_resp,
    // input iq_resp,
    input [31:0] in,
    input [31:0] pc,
    input br_pr_take,
    input executed_jalr,

    output rv32i_word instr_mem_address, // ir will have to communicate with pc to get this, or maybe pc just wires directly to icache
    output logic instr_read,
    // output tomasula_types::ctl_word control_word,
    output logic ld_pc,
    output logic [31:0] pc_calc,
    // output logic ld_pc_calc,
    // output logic ld_iq, 

    IQ_2_IR.IR_SIG iq_ir_itf
);

logic [31:0] data; // holds current instruction from cache
// logic [31:0] curr_pc; // holds current pc to add to control word
logic locked_instr_mem_resp; // since i-cache works on the falling edges for some reason

logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] i_imm, s_imm, b_imm, j_imm, u_imm;
logic [4:0] rs1, rs2, rd;
rv32i_opcode opcode;

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]}; // 32
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];

// assign iq_ir_itf.control_word.src1_reg = rs1;
// assign iq_ir_itf.control_word.src2_reg = rs2;
// assign iq_ir_itf.control_word.src1_valid = 1'b0;
assign iq_ir_itf.control_word.funct3 = funct3;
assign iq_ir_itf.control_word.funct7 = data[30];
// assign iq_ir_itf.control_word.rd = rd;
// assign iq_ir_itf.control_word.pc = pc + 4; // necessary for instructions that need to load pc (br and jalr)

assign instr_mem_address = pc; //curr_pc;

enum int unsigned {
    RESET = 0,
    FETCH = 1,
    CREATE = 2,
    STALL = 3,
    STALL_JALR = 4
} state, next_state;

always_comb
begin : immediate_op_logic
    iq_ir_itf.control_word.src1_reg = rs1;
    iq_ir_itf.control_word.src1_valid = 1'b0;
    iq_ir_itf.control_word.src2_data = 32'h0000;
    iq_ir_itf.control_word.src2_valid = 1'b0;
    iq_ir_itf.control_word.op = tomasula_types::ARITH;
    iq_ir_itf.control_word.src2_reg = rs2; // should be rs2 if no immediate is used, otherwise 0
    iq_ir_itf.control_word.rd = rd;
    case (opcode)
        op_lui: begin
            iq_ir_itf.control_word.src2_data = u_imm;
            iq_ir_itf.control_word.op = tomasula_types::LUI;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end
        op_auipc: begin 
            iq_ir_itf.control_word.op = tomasula_types::AUIPC;
            //iq_ir_itf.control_word.src1_reg = 5'b00000;
            //iq_ir_itf.control_word.src1_data = pc;
            //iq_ir_itf.control_word.src1_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            iq_ir_itf.control_word.src2_data = pc + u_imm;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.pc = pc + u_imm;
        end
        op_jal: begin
            // iq_ir_itf.control_word.src2_data = j_imm;
            iq_ir_itf.control_word.src1_reg = 5'b00000;
            // iq_ir_itf.control_word.src1_valid = 1'b1; // possibly don't need this since src1_valid from RegFile for register 0 should always be 1'b1
            //iq_ir_itf.control_word.src2_data = pc + 4; // jal places pc + 4 into a register
            iq_ir_itf.control_word.src2_data = pc_calc; // jal places pc + 4 into a register
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
            // ld_pc_calc = 1'b1;
        end
        op_br: begin
            iq_ir_itf.control_word.op = tomasula_types::BRANCH;
            /* if branch not taken, need address that would've been taken in case of branch mispredict; by default will have pc + 4 */
            if (~br_pr_take) begin
                iq_ir_itf.control_word.pc = pc_calc;
                iq_ir_itf.control_word.rd = 5'b00000; // second bit used to indicate if branch was predicted to be taken or not taken

            end
                iq_ir_itf.control_word.rd = 5'b00010;
            
        end
        op_store: begin
            iq_ir_itf.control_word.src2_data = s_imm;
            iq_ir_itf.control_word.op = tomasula_types::ST;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end
        op_imm: begin
            iq_ir_itf.control_word.src2_data = i_imm;
            iq_ir_itf.control_word.op = tomasula_types::ARITH;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end 
        op_csr: begin
            iq_ir_itf.control_word.src2_data = i_imm;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end
        op_jalr: begin
            iq_ir_itf.control_word.src2_data = i_imm;
            iq_ir_itf.control_word.op = tomasula_types::JALR;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end
        op_load: begin
            iq_ir_itf.control_word.src2_data = i_imm;
            iq_ir_itf.control_word.op = tomasula_types::LD;
            iq_ir_itf.control_word.src2_valid = 1'b1;
            iq_ir_itf.control_word.src2_reg = 5'b00000;
        end
        op_store: begin
            iq_ir_itf.control_word.op = tomasula_types::ST;
        end
    endcase
end

//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
        // curr_pc <= '0;
        state <= RESET;
        locked_instr_mem_resp <= 1'b0;
    end
    else if (next_state == FETCH)
    begin
        // data <= in;
        // curr_pc <= pc;
        state <= next_state;
    end
    else if (next_state == CREATE)
    begin
        data <= in;
        state <= next_state;
    end
    // else if (next_state == STALL)
    else
        state <= next_state;
    if (instr_mem_resp)
        locked_instr_mem_resp <= 1'b1;
    else
        locked_instr_mem_resp <= 1'b0;

end

function void set_defaults();
    instr_read = 1'b0;
    ld_pc = 1'b0;
    iq_ir_itf.ld_iq = 1'b0;
    pc_calc = pc + 4;
endfunction

always_comb
begin : state_actions
    set_defaults();

    case (state)
        RESET: ;
        FETCH: begin
            instr_read = 1'b1;
        end
        CREATE: begin
            // address calculation 
            if(opcode == op_jal) begin
                pc_calc = pc + j_imm;
            end
            if(opcode == op_br) begin
                pc_calc = pc + b_imm;
            end
            /*
            intuitively, we only we wouldn't care about the next instruction if the opcode is jalr but we can safely
            assume with the jalr_stall state that even though pc gets loaded with pc + 4, we will never fetch this address from i-cache,
            we will only fetch the calculated address from jalr since jalr will load pc with its calculated address eventually in order to
            leave the jalr_stall state
            */
            ld_pc = 1'b1; 
            iq_ir_itf.ld_iq = 1'b1;
        end
        STALL: begin

            iq_ir_itf.ld_iq = 1'b1;
        end
        STALL_JALR: begin

        end
    endcase
end

always_comb
begin : next_state_logic
    next_state = state;
    case(state)
        RESET: next_state = FETCH;
        FETCH: begin
            if (instr_mem_resp)
            // if (locked_instr_mem_resp)
                next_state = CREATE;
        end
        CREATE: begin
            if (iq_ir_itf.ack_o) begin
                if(opcode == op_jalr) 
                    next_state = STALL_JALR;
                else
                    next_state = FETCH;
            end
        end
        STALL: begin
            if (iq_ir_itf.ack_o) begin
                if(opcode == op_jalr) 
                    next_state = STALL_JALR;
                else
                    next_state = FETCH;
            end
        end
        STALL_JALR: begin
            if(executed_jalr == 1) begin
                next_state = FETCH;
            end
        end
    endcase
end

endmodule : ir
