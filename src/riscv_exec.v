`timescale 1ns / 1ps
`include "riscv_defs.v"

module riscv_exec (
    input clk_i,  // Clock signal
    input rst_i,  // Reset signal
    input opcode_valid_i,  // Validity signal for instruction execution
    input [57:0] opcode_instr_i,  // Encoded instruction type and operation
    input [31:0] opcode_opcode_i,  // Full instruction encoding
    input [31:0] opcode_pc_i,  // Program Counter value
    input [4:0] opcode_rd_idx_i,  // Destination register index
    input [4:0] opcode_ra_idx_i,  // First source register index (rs1)
    input [4:0] opcode_rb_idx_i,  // Second source register index (rs2)
    input [31:0] opcode_ra_operand_i,  // Value of rs1
    input [31:0] opcode_rb_operand_i,  // Value of rs2
    output wire branch_request_o,  // Branch request signal
    output wire [31:0] branch_pc_o,  // Target address for branch/jump
    output wire [4:0] writeback_idx_o,  // Register index for result write-back
    output wire writeback_squash_o,  // Signal for writeback cancellation (set to 0)
    output wire [31:0] writeback_value_o,  // Computed result
    output wire stall_o  // Stall signal (set to 0)
);
 // Internal registers
    reg branch_request_o_c;
    reg [3:0] alu_func_r;
    reg [31:0] alu_input_a_r, alu_input_b_r;
    wire [31:0] alu_p_w;

    // ALU instantiation
    riscv_alu u_alu (
        .alu_op_i(alu_func_r),
        .alu_a_i(alu_input_a_r),
        .alu_b_i(alu_input_b_r),
        .alu_p_o(alu_p_w)
    );
    reg [31:0] ax,bx;
    wire [31:0]Y;
    wire Cout; 
    BK_Adder_32 adderr(.Y(Y), .Cout(Cout), .A(ax), .B(bx), .Cin(1'b0));
     
    
    
    reg branch_request_o_r, writeback_squash_o_r, stall_o_r;
    reg [4:0] writeback_idx_o_r;
    reg [31:0] result_q, branch_pc_o_r,branch_pc_o_r1;
    
    always @(*) begin
        
        
            writeback_idx_o_r <= 5'b0;
            writeback_squash_o_r <= 1'b1;
            stall_o_r <= 1'b0;
            result_q<=31'b0; 
            branch_pc_o_r1<=1'b0;
            branch_pc_o_r1<=1'b0;            
         if (opcode_valid_i)
         begin
           if (
      opcode_instr_i[`ENUM_INST_ADDI]   ||
      opcode_instr_i[`ENUM_INST_ANDI]   ||
      opcode_instr_i[`ENUM_INST_ORI]    ||
      opcode_instr_i[`ENUM_INST_XORI]   ||
      opcode_instr_i[`ENUM_INST_SLLI]   ||
      opcode_instr_i[`ENUM_INST_SRLI]   ||
      opcode_instr_i[`ENUM_INST_SRAI]   ||
      opcode_instr_i[`ENUM_INST_LUI]    ||
      opcode_instr_i[`ENUM_INST_AUIPC]  ||
      opcode_instr_i[`ENUM_INST_ADD]    ||
      opcode_instr_i[`ENUM_INST_SUB]    ||
      opcode_instr_i[`ENUM_INST_SLT]    ||
      opcode_instr_i[`ENUM_INST_SLTU]   ||
      opcode_instr_i[`ENUM_INST_XOR]    ||
      opcode_instr_i[`ENUM_INST_OR]     ||
      opcode_instr_i[`ENUM_INST_AND]    ||
      opcode_instr_i[`ENUM_INST_SLL]    ||
      opcode_instr_i[`ENUM_INST_SRL]    ||
      opcode_instr_i[`ENUM_INST_SRA]    ||
      opcode_instr_i[`ENUM_INST_JAL]    ||
      opcode_instr_i[`ENUM_INST_JALR]
     )
            writeback_squash_o_r <= 1'b0;
            branch_request_o_r <= branch_request_o_c;
            branch_pc_o_r1<=branch_pc_o_r;
            case (opcode_opcode_i[6:0])
                7'b0110011, 7'b0010011, 7'b0110111, 7'b0010111, 7'b1101111, 7'b1100111: 
                begin
                    result_q <= alu_p_w;
                    writeback_idx_o_r <= opcode_rd_idx_i;
                end
//                7'b1100011 :
//                 begin
//                    result_q <= alu_p_w;
//                    writeback_idx_o_r <= opcode_rd_idx_i;
//                end
//               7'b1100011:
               
//               begin
//               result_q1<=
//               end
                
                        default: begin
                    writeback_idx_o_r <= 5'b0;
                    result_q          <=32'b0;
                    
                 //   branch_request_o_r <= 1'b0; // Prevent latch inference
                    
                end
            endcase
        end
    end
    
    // Assign outputs
    assign branch_request_o = branch_request_o_r;
    assign branch_pc_o  = branch_pc_o_r1;
    assign writeback_idx_o  = writeback_idx_o_r;
    assign writeback_squash_o = writeback_squash_o_r;
    assign writeback_value_o = result_q;  
    assign stall_o  = stall_o_r;
    
    
    //debugging
    wire [31:0] branchcode1,branchcode2,shifted_branchcode2,jumpcode1,jumpcode2,shifted_jumpcode2;
    wire   [31:0]  jalrcode1,jalrcode2,jalrresult,shifted_jalrresult;
    
    assign branchcode1 =opcode_pc_i;
    assign branchcode2= {{20{opcode_opcode_i[31]}}, opcode_opcode_i[7], opcode_opcode_i[30:25], opcode_opcode_i[11:8]};
    assign shifted_branchcode2={{20{opcode_opcode_i[31]}}, opcode_opcode_i[7], opcode_opcode_i[30:25], opcode_opcode_i[11:8], 1'b0};
    
    assign jumpcode1 =opcode_pc_i;
    assign jumpcode2= {{12{opcode_opcode_i[31]}}, opcode_opcode_i[19:12], opcode_opcode_i[20], opcode_opcode_i[30:21]};
    assign shifted_jumpcode2={{12{opcode_opcode_i[31]}}, opcode_opcode_i[19:12], opcode_opcode_i[20], opcode_opcode_i[30:21], 1'b0};
  
    
    assign jalrcode1=opcode_ra_operand_i;
    assign jalrcode2 ={{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]};
    assign jalrresult= (opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]});
    assign shifted_jalrresult=(opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]}) & ~1;
    wire cout;
    //(opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]}) & ~1;
   // Combinational logic for instruction decoding 
    always @(*) begin
        if (opcode_valid_i) begin
            case (opcode_opcode_i[6:0])
            
//            // ALU operations (R-type)
//                7'b0110011: begin
//                    case (1'b1)
////                        opcode_instr_i[`ENUM_INST_ADD]:  alu_func_r = 4'b0000;
////                        opcode_instr_i[`ENUM_INST_SUB]:  alu_func_r = 4'b0001;
////                        opcode_instr_i[`ENUM_INST_AND]:  alu_func_r = 4'b0010;
////                        opcode_instr_i[`ENUM_INST_OR]:   alu_func_r = 4'b0011;
////                        opcode_instr_i[`ENUM_INST_XOR]:  alu_func_r = 4'b0100;
////                        opcode_instr_i[`ENUM_INST_SLL]:  alu_func_r = 4'b0101;
////                        opcode_instr_i[`ENUM_INST_SRL]:  alu_func_r = 4'b0110;
////                        opcode_instr_i[`ENUM_INST_SRA]:  alu_func_r = 4'b0111;
////                        opcode_instr_i[`ENUM_INST_SLT]:  alu_func_r = 4'b1000;
////                        opcode_instr_i[`ENUM_INST_SLTU]: alu_func_r = 4'b1001;
                        
//                        opcode_instr_i[`ENUM_INST_ADD]:  alu_func_r = 4'b0100; // `ALU_ADD`
//                        opcode_instr_i[`ENUM_INST_SUB]:  alu_func_r = 4'b0110; // `ALU_SUB`
//                        opcode_instr_i[`ENUM_INST_AND]:  alu_func_r = 4'b0111; // `ALU_AND`
//                        opcode_instr_i[`ENUM_INST_OR]:   alu_func_r = 4'b1000; // `ALU_OR`
//                        opcode_instr_i[`ENUM_INST_XOR]:  alu_func_r = 4'b1001; // `ALU_XOR`
//                        opcode_instr_i[`ENUM_INST_SLL]:  alu_func_r = 4'b0001; // `ALU_SHIFTL`
//                        opcode_instr_i[`ENUM_INST_SRL]:  alu_func_r = 4'b0010; // `ALU_SHIFTR`
//                        opcode_instr_i[`ENUM_INST_SRA]:  alu_func_r = 4'b0011; // `ALU_SHIFTR_ARITH`
//                        opcode_instr_i[`ENUM_INST_SLT]:  alu_func_r = 4'b1011; // `ALU_LESS_THAN_SIGNED`
//                        opcode_instr_i[`ENUM_INST_SLTU]: alu_func_r = 4'b1010; // `ALU_LESS_THAN`

                        
                        
//                    endcase
//                    alu_input_a_r = opcode_ra_operand_i;
//                    alu_input_b_r = opcode_rb_operand_i;
//                    branch_request_o_c = 0;
//                end
             
                                    // ALU operations (R-type)
                    7'b0110011: begin
                        case (1'b1)
                            opcode_instr_i[`ENUM_INST_ADD]:  alu_func_r = 4'b0000; // `ALU_ADD`
                            opcode_instr_i[`ENUM_INST_SUB]:  alu_func_r = 4'b0001; // `ALU_SUB`
                            opcode_instr_i[`ENUM_INST_AND]:  alu_func_r = 4'b0010; // `ALU_AND`
                            opcode_instr_i[`ENUM_INST_OR]:   alu_func_r = 4'b0011; // `ALU_OR`
                            opcode_instr_i[`ENUM_INST_XOR]:  alu_func_r = 4'b0100; // `ALU_XOR`
                            opcode_instr_i[`ENUM_INST_SLL]:  alu_func_r = 4'b0101; // `ALU_SHIFTL`
                            opcode_instr_i[`ENUM_INST_SRL]:  alu_func_r = 4'b0110; // `ALU_SHIFTR`
                            opcode_instr_i[`ENUM_INST_SRA]:  alu_func_r = 4'b0111; // `ALU_SHIFTR_ARITH`
                            opcode_instr_i[`ENUM_INST_SLT]:  alu_func_r = 4'b1000; // `ALU_LESS_THAN_SIGNED`
                            opcode_instr_i[`ENUM_INST_SLTU]: alu_func_r = 4'b1001; // `ALU_LESS_THAN`
                            opcode_instr_i[`ENUM_INST_MUL]:  alu_func_r = 4'b1010; // `ALU_MUL` (Assuming `1100` is the ALU function for multiplication)
                        endcase
                        
                        alu_input_a_r = opcode_ra_operand_i;
                        alu_input_b_r = opcode_rb_operand_i;
                        branch_request_o_c = 0;
                    end
                   // Immediate ALU operations (I-type) 
                7'b0010011: begin
                    alu_input_a_r = opcode_ra_operand_i;
                    alu_input_b_r = {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]};
                  branch_request_o_c = 0;

                    case (1'b1)
//                        opcode_instr_i[`ENUM_INST_ADDI]:  alu_func_r = 4'b0000;
//                        opcode_instr_i[`ENUM_INST_ANDI]:  alu_func_r = 4'b0010;
//                        opcode_instr_i[`ENUM_INST_ORI]:   alu_func_r = 4'b0011;
//                        opcode_instr_i[`ENUM_INST_XORI]:  alu_func_r = 4'b0100;
//                        opcode_instr_i[`ENUM_INST_SLLI]:  alu_func_r = 4'b0101;
//                        opcode_instr_i[`ENUM_INST_SRLI]:  alu_func_r = 4'b0110;
//                        opcode_instr_i[`ENUM_INST_SRAI]:  alu_func_r = 4'b0111;

                        opcode_instr_i[`ENUM_INST_ADDI]:  alu_func_r = 4'b0000; // `ALU_ADD`
                        opcode_instr_i[`ENUM_INST_ANDI]:  alu_func_r = 4'b0010; // `ALU_AND`
                        opcode_instr_i[`ENUM_INST_ORI]:   alu_func_r = 4'b0011; // `ALU_OR`
                        opcode_instr_i[`ENUM_INST_XORI]:  alu_func_r = 4'b0100; // `ALU_XOR`
                        opcode_instr_i[`ENUM_INST_SLLI]:  alu_func_r = 4'b0101; // `ALU_SHIFTL`
                        opcode_instr_i[`ENUM_INST_SRLI]:  alu_func_r = 4'b0110; // `ALU_SHIFTR`
                        opcode_instr_i[`ENUM_INST_SRAI]:  alu_func_r = 4'b0111; // `ALU_SHIFTR_ARITH`

                    endcase
                end
                
                // Branch instruction handling
                7'b1100011: begin
                    case (1'b1)
                        opcode_instr_i[`ENUM_INST_BEQ]:  branch_request_o_c = (opcode_ra_operand_i == opcode_rb_operand_i);
                        opcode_instr_i[`ENUM_INST_BNE]:  branch_request_o_c = (opcode_ra_operand_i != opcode_rb_operand_i);
                        opcode_instr_i[`ENUM_INST_BLT]:  branch_request_o_c = ($signed(opcode_ra_operand_i) < $signed(opcode_rb_operand_i));
                        opcode_instr_i[`ENUM_INST_BGE]:  branch_request_o_c = ($signed(opcode_ra_operand_i) >= $signed(opcode_rb_operand_i));
                        opcode_instr_i[`ENUM_INST_BLTU]: branch_request_o_c = ($unsigned(opcode_ra_operand_i) < $unsigned(opcode_rb_operand_i));
                        opcode_instr_i[`ENUM_INST_BGEU]: branch_request_o_c = ($unsigned(opcode_ra_operand_i) >= $unsigned(opcode_rb_operand_i));
                    endcase
                    if (branch_request_o_c)
                     alu_func_r = 4'b0000;
                    alu_input_a_r     = opcode_pc_i;
                       alu_input_b_r =   {{20{opcode_opcode_i[31]}}, opcode_opcode_i[7], opcode_opcode_i[30:25], opcode_opcode_i[11:8], 1'b0};
                        branch_pc_o_r=alu_p_w;
                end
                
                // JAL (Jump and Link) instruction handling
                7'b1101111: begin
                    if (opcode_instr_i[`ENUM_INST_JAL]) begin
                   
                    
                        branch_request_o_c = 1;
//                        alu_input_a_r = opcode_pc_i;
//                         alu_input_b_r = {{12{opcode_opcode_i[31]}}, opcode_opcode_i[19:12], opcode_opcode_i[20], opcode_opcode_i[30:21], 1'b0};
//                        branch_pc_o_r =alu_p_w;
                     //   bk32_add_sub a1 (,cout,opcode_pc_i,{{12{opcode_opcode_i[31]}}, opcode_opcode_i[19:12], opcode_opcode_i[20], opcode_opcode_i[30:21], 1'b0},1'b0);
                       ax =opcode_pc_i;
                       bx={{12{opcode_opcode_i[31]}}, opcode_opcode_i[19:12], opcode_opcode_i[20], opcode_opcode_i[30:21], 1'b0};
                        branch_pc_o_r = Y;
                        alu_input_a_r = opcode_pc_i;
                        alu_input_b_r = 32'd4;
                        alu_func_r = 4'b0000;
                    end
                end
                // JALR (Jump and Link Register) instruction handling
                7'b1100111: begin
                    if (opcode_instr_i[`ENUM_INST_JALR]) begin
                        branch_request_o_c = 1;
                        
                       ax =opcode_ra_operand_i;
                       bx={{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]};
                        branch_pc_o_r = Y;
                      //  branch_pc_o_r = (opcode_ra_operand_i + {{20{opcode_opcode_i[31]}}, opcode_opcode_i[31:20]}) & ~1;
                        alu_input_a_r = opcode_pc_i;
                        alu_input_b_r = 32'd4;
                        alu_func_r = 4'b0000;
                    end
                end
                
             // LUI (Load Upper Immediate)

                7'b0110111: begin
                    branch_request_o_c= 0;

                    alu_input_a_r = 32'b0;
                    alu_input_b_r = {opcode_opcode_i[31:12], 12'b0};
                    alu_func_r = 4'b0000;
                end
              // AUIPC (Add Upper Immediate to PC)

                7'b0010111: begin
                    branch_request_o_c= 0;
                    alu_input_a_r = opcode_pc_i;
                    alu_input_b_r = {opcode_opcode_i[31:12], 12'b0};
                    alu_func_r = 4'b0000;
                end
                
                
                
                
                
                default: begin
                    alu_input_a_r = 32'b0;
                    alu_input_b_r = 32'b0;
                    alu_func_r = 4'b0000;
                    branch_request_o_c= 0;
                    branch_pc_o_r = 32'b0;
                end
            endcase
        end
    end
endmodule
